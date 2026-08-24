# Dotfiles

A modular macOS and Ubuntu/Debian development environment managed with [GNU Stow](https://www.gnu.org/software/stow/). Shell behavior is shared between Bash and Zsh, while application configuration remains independently installable.

## Quick start

```bash
git clone git@github.com:jordanmessina/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

To also apply the optional macOS defaults:

```bash
./bootstrap.sh --macos-defaults
```

The bootstrap is designed to be rerunnable. Existing conflicting dotfiles are moved into a timestamped `~/dotfiles_backup_*` directory before links are created.

## Bootstrap options

```text
--macos-defaults  Apply macos/defaults.sh
--skip-packages   Skip Homebrew/apt packages, but install user-level tools
--stow-only       Only back up conflicts and link dotfiles
-h, --help        Show help
```

Convenience targets are also available:

```bash
make bootstrap
make stow
make test
make test-docker
```

## What is installed

### macOS

Homebrew dependencies are declared in [`Brewfile`](Brewfile):

- Core tools: Vim, Neovim, tmux, pyenv, Starship, Stow, pipx, htop, nmap, wget, and tree
- Modern CLI tools: fzf, eza, bat, fd, ripgrep, lazygit, and the tree-sitter CLI
- Agent tooling: HerdR
- Validation: ShellCheck
- Font: JetBrains Mono Nerd Font

Homebrew itself must already be installed.

### Linux

The Ubuntu/Debian bootstrap installs the equivalent apt and user-level tools, including:

- Bash and Zsh support, `lsof`, ShellCheck, and `xclip`
- Build dependencies required by pyenv
- Neovim >= 0.11.2, tree-sitter, and lazygit for LazyVim
- Starship, pyenv, pipx, Stow, and modern CLI tools
- JetBrains Mono Nerd Font

### Cross-platform user tools

The bootstrap also:

- Installs NVM and the latest Node.js LTS release
- Sets `lts/*` as NVM's default Node version
- Installs OpenCode through its official installer
- Installs Pi non-interactively from the official `@earendil-works/pi-coding-agent` npm package
- Installs the user-scoped Pi packages declared in [`PiPackages`](PiPackages)
- Installs HerdR through Homebrew on macOS or its official installer on Linux
- Installs Black and Flake8 with pipx
- Installs Vundle and the configured Vim plugins
- Configures Ghostty shell integration to install terminfo automatically over SSH

## Repository structure

```text
.
├── bash/                    # ~/.bashrc and ~/.bash_profile
├── ghostty/                 # ~/.config/ghostty/config
├── herdr/                   # ~/.config/herdr/config.toml
├── macos/                   # Optional macOS defaults
├── misc/                    # ~/.hushlogin
├── nvim/                    # ~/.config/nvim (LazyVim)
├── pi/                      # ~/.pi configuration
├── shell/                   # Shared aliases, exports, functions, etc.
├── starship/                # ~/.config/starship.toml
├── tmux/                    # ~/.tmux.conf
├── vim/                     # ~/.vimrc
├── zsh/                     # ~/.zshrc
├── Brewfile                 # Homebrew dependency manifest
├── PiPackages               # User-scoped Pi package manifest
├── bootstrap.sh             # Cross-platform installer
└── scripts/                 # Local and Docker validation
```

Each Stow package mirrors its destination under `$HOME`. For example, `starship/.config/starship.toml` becomes `~/.config/starship.toml`.

## Shell configuration

Bash and Zsh both source modules from `~/.shell/`:

- `exports` — PATH, NVM, pyenv, and Starship initialization
- `aliases` — navigation, Git, and macOS Finder aliases
- `functions` — file, Python, networking, and fzf helpers
- `keybindings` — shared Emacs-style line navigation
- `completions` — completion for custom functions

Notable commands include:

- `mkcd <dir>` — create and enter a directory
- `up [n]` — move up directory levels
- `extract <archive>` — extract common archive formats
- `serve [port]` — start a Python HTTP server
- `killport <port>` — kill listeners on a port
- `mkvenv` — create and activate `.venv`
- `venv` — find and activate a parent `.venv`
- `myip` — show internal and external addresses
- `gadd` / `gbr` — fzf Git helpers

When available, `ls` uses eza and `cat` uses bat.

## Editors

### Neovim

The Neovim package is a LazyVim setup with pinned plugin revisions and TypeScript and JSON extras. On first launch:

```bash
nvim
```

Then run `:LazyHealth`.

### Vim

The fallback Vim configuration uses Vundle, a colorscheme collection, four-space indentation, and Black-on-save for Python files.

## Pi packages

[`PiPackages`](PiPackages) lists the third-party Pi packages that bootstrap installs with `pi install`. It includes `pi-mcp-adapter` for MCP integrations, `pi-web-access` for web search and content extraction, and the commit-pinned public [`pi-fork-agent`](https://github.com/jordanmessina/pi-fork-agent) Git package for focused delegation.

`pi/.pi/web-search.json` configures `pi-web-access` to permit loopback, private LAN, Docker/Kubernetes, Tailscale/CGNAT, and local IPv6 ranges. Literal `localhost` URLs remain blocked by the extension; use `127.0.0.1` or `[::1]`.

The Git-installed [`pi-fork-agent`](https://github.com/jordanmessina/pi-fork-agent) package adds `fork_agent`. It copies the exact active conversation branch into a linked child session, appends one focused task, and preserves the parent's provider cache key and runtime configuration. Each child runs in a separate Pi SDK process with checked tool ordering and public schema fields, giving concurrent children independent WebSocket and continuation state. Child prompts forbid further delegation, model-invisible markers reject recursive calls and child compaction, and the parent receives only bounded final-answer text. Persisted parents keep inspectable child sessions beside the parent JSONL file. Provider serialization and cache behavior remain provider-dependent.

Each machine keeps its own `~/.pi/agent/settings.json`, credentials, and runtime state.

## HerdR

Only the hand-authored `~/.config/herdr/config.toml` is tracked. HerdR logs, sockets, plugin state, and session state remain local and are ignored.

On Linux, Zsh is installed but is not automatically made the login shell. To opt in:

```bash
chsh -s "$(command -v zsh)"
```

## Manual Stow usage

Install selected packages without running bootstrap:

```bash
mkdir -p ~/.config/ghostty ~/.config/herdr ~/.pi
stow --target="$HOME" shell zsh starship tmux nvim ghostty herdr pi
```

Remove links for a package:

```bash
stow --delete --target="$HOME" nvim
```

## Testing

Run local syntax, ShellCheck, Stow, shell smoke, and Pi configuration checks:

```bash
./scripts/test.sh
```

Run a complete Linux bootstrap in a clean Ubuntu container:

```bash
./scripts/test-docker.sh
```

See [`TEST.md`](TEST.md) for details. GitHub Actions performs repository checks and validates the Docker image on pushes and pull requests.

## Security note

The bootstrap uses official network installers for NVM, pyenv, Starship, OpenCode, and HerdR. Pi is installed directly from its official npm package. Review remote installers and packages before running the bootstrap in a sensitive environment.

## License

[MIT](LICENSE)
