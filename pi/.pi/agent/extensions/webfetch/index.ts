import { Buffer } from "node:buffer";
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  truncateHead,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import TurndownService from "turndown";
import { Type } from "typebox";

const MAX_RESPONSE_SIZE = 5 * 1024 * 1024; // 5MB
const DEFAULT_TIMEOUT = 30 * 1000; // 30 seconds
const MAX_TIMEOUT = 120 * 1000; // 2 minutes

const Parameters = Type.Object({
  url: Type.String({ description: "The URL to fetch content from" }),
  format: Type.Optional(
    Type.Union([Type.Literal("text"), Type.Literal("markdown"), Type.Literal("html")], {
      description: "The format to return the content in (text, markdown, or html). Defaults to markdown.",
      default: "markdown",
    }),
  ),
  timeout: Type.Optional(Type.Number({ description: "Optional timeout in seconds (max 120)" })),
});

type WebFetchFormat = "text" | "markdown" | "html";

interface WebFetchDetails {
  url: string;
  title: string;
  status: number;
  contentType: string;
  mime: string;
  format: WebFetchFormat;
  timeoutMs: number;
  byteLength: number;
  truncated?: boolean;
  fullOutputPath?: string;
  image?: boolean;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "webfetch",
    label: "Web Fetch",
    description:
      "Fetch a URL and return the response body as text, Markdown, or HTML. Defaults to Markdown. Responses over 5MB are rejected; large text output is truncated and saved to a temp file.",
    promptSnippet: "Fetch web pages or URLs and return text, Markdown, HTML, or images",
    promptGuidelines: [
      "Use webfetch when the user asks to read or summarize the contents of a URL.",
      "Prefer webfetch format=markdown for HTML pages unless the user asks for raw HTML or plain text.",
    ],
    parameters: Parameters,

    async execute(_toolCallId, params, signal) {
      const url = parseHttpUrl(params.url);
      const format = params.format ?? "markdown";
      const timeoutMs = Math.min((params.timeout ?? DEFAULT_TIMEOUT / 1000) * 1000, MAX_TIMEOUT);
      const headers = buildHeaders(format);

      let response = await fetchWithTimeout(url, { headers }, timeoutMs, signal);

      // Retry with honest UA if blocked by Cloudflare bot detection (TLS fingerprint mismatch).
      if (response.status === 403 && response.headers.get("cf-mitigated") === "challenge") {
        response = await fetchWithTimeout(
          url,
          { headers: { ...headers, "User-Agent": "pi-webfetch" } },
          timeoutMs,
          signal,
        );
      }

      if (!response.ok) {
        throw new Error(`Request failed: ${response.status} ${response.statusText}`);
      }

      const contentLength = response.headers.get("content-length");
      if (contentLength && Number.parseInt(contentLength, 10) > MAX_RESPONSE_SIZE) {
        throw new Error("Response too large (exceeds 5MB limit)");
      }

      const arrayBuffer = await response.arrayBuffer();
      if (arrayBuffer.byteLength > MAX_RESPONSE_SIZE) {
        throw new Error("Response too large (exceeds 5MB limit)");
      }

      const contentType = response.headers.get("content-type") ?? "";
      const mime = contentType.split(";")[0]?.trim().toLowerCase() || "";
      const title = `${url.toString()} (${contentType})`;

      const details: WebFetchDetails = {
        url: url.toString(),
        title,
        status: response.status,
        contentType,
        mime,
        format,
        timeoutMs,
        byteLength: arrayBuffer.byteLength,
      };

      if (isImageAttachment(mime)) {
        details.image = true;
        const base64Content = Buffer.from(arrayBuffer).toString("base64");
        return {
          content: [
            { type: "text" as const, text: "Image fetched successfully" },
            { type: "image" as const, data: base64Content, mimeType: mime },
          ],
          details,
        };
      }

      const content = new TextDecoder().decode(arrayBuffer);
      const output = formatContent(content, format, contentType.includes("text/html"));
      const { text, truncated, fullOutputPath } = await truncateToolOutput(output);

      if (truncated) {
        details.truncated = true;
        details.fullOutputPath = fullOutputPath;
      }

      return {
        content: [{ type: "text" as const, text }],
        details,
      };
    },
  });
}

function parseHttpUrl(input: string): URL {
  let url: URL;
  try {
    url = new URL(input);
  } catch {
    throw new Error("Invalid URL");
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error("URL must start with http:// or https://");
  }

  return url;
}

function buildHeaders(format: WebFetchFormat): Record<string, string> {
  let acceptHeader = "*/*";

  switch (format) {
    case "markdown":
      acceptHeader = "text/markdown;q=1.0, text/x-markdown;q=0.9, text/plain;q=0.8, text/html;q=0.7, */*;q=0.1";
      break;
    case "text":
      acceptHeader = "text/plain;q=1.0, text/markdown;q=0.9, text/html;q=0.8, */*;q=0.1";
      break;
    case "html":
      acceptHeader = "text/html;q=1.0, application/xhtml+xml;q=0.9, text/plain;q=0.8, text/markdown;q=0.7, */*;q=0.1";
      break;
  }

  return {
    "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36",
    Accept: acceptHeader,
    "Accept-Language": "en-US,en;q=0.9",
  };
}

async function fetchWithTimeout(
  url: URL,
  init: RequestInit,
  timeoutMs: number,
  parentSignal: AbortSignal | undefined,
): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(new Error("Request timed out")), timeoutMs);

  const abortFromParent = () => controller.abort(parentSignal?.reason);
  if (parentSignal?.aborted) abortFromParent();
  parentSignal?.addEventListener("abort", abortFromParent, { once: true });

  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } catch (error) {
    if (controller.signal.aborted && !parentSignal?.aborted) {
      throw new Error("Request timed out");
    }
    throw error;
  } finally {
    clearTimeout(timeout);
    parentSignal?.removeEventListener("abort", abortFromParent);
  }
}

function formatContent(content: string, format: WebFetchFormat, isHtml: boolean): string {
  if (format === "html" || !isHtml) {
    return content;
  }

  if (format === "markdown") {
    return htmlToMarkdown(content);
  }

  return htmlToText(content);
}

function htmlToText(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, "")
    .replace(/<iframe[\s\S]*?<\/iframe>/gi, "")
    .replace(/<object[\s\S]*?<\/object>/gi, "")
    .replace(/<embed[\s\S]*?<\/embed>/gi, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function htmlToMarkdown(html: string): string {
  const turndown = new TurndownService({
    headingStyle: "atx",
    hr: "---",
    bulletListMarker: "-",
    codeBlockStyle: "fenced",
    emDelimiter: "*",
  });

  turndown.remove(["script", "style", "meta", "link"]);

  return turndown.turndown(html).trim();
}

function isImageAttachment(mime: string): boolean {
  return mime.startsWith("image/") && mime !== "image/svg+xml" && mime !== "image/vnd.fastbidsheet";
}

async function truncateToolOutput(output: string): Promise<{
  text: string;
  truncated: boolean;
  fullOutputPath?: string;
}> {
  const truncation = truncateHead(output, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  });

  if (!truncation.truncated) {
    return { text: output, truncated: false };
  }

  const tempDir = await mkdtemp(join(tmpdir(), "pi-webfetch-"));
  const fullOutputPath = join(tempDir, "output.txt");
  await writeFile(fullOutputPath, output, "utf8");

  const text = `${truncation.content}\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines (${formatSize(
    truncation.outputBytes,
  )} of ${formatSize(truncation.totalBytes)}). Full output saved to: ${fullOutputPath}]`;

  return { text, truncated: true, fullOutputPath };
}
