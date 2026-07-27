#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=(bash shell zsh tmux vim nvim misc starship pi herdr)
SHELL_FILES=(
    bootstrap.sh
    macos/defaults.sh
    bash/.bashrc
    bash/.bash_profile
    zsh/.zshrc
    shell/.shell/exports
    shell/.shell/aliases
    shell/.shell/functions
    shell/.shell/keybindings
    shell/.shell/completions
)

cd "$ROOT"

echo "Checking Bash syntax..."
bash -n "${SHELL_FILES[@]}"

if command -v zsh >/dev/null 2>&1; then
    echo "Checking Zsh syntax..."
    zsh -n zsh/.zshrc shell/.shell/exports shell/.shell/aliases \
        shell/.shell/functions shell/.shell/keybindings shell/.shell/completions
fi

if command -v shellcheck >/dev/null 2>&1; then
    echo "Running ShellCheck..."
    shellcheck -x bootstrap.sh macos/defaults.sh bash/.bashrc bash/.bash_profile \
        scripts/test.sh scripts/test-docker.sh scripts/verify-bootstrap.sh
    # These files intentionally support both Bash and Zsh; lint their shared
    # POSIX/Bash-compatible portions as Bash and rely on zsh -n for Zsh syntax.
    shellcheck -x -s bash shell/.shell/exports shell/.shell/aliases \
        shell/.shell/functions shell/.shell/keybindings
else
    echo "ShellCheck is not installed; skipping lint."
fi

echo "Testing Stow packages in an isolated home..."
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
mkdir -p "$test_home/.config/herdr" "$test_home/.pi/agent/extensions"
stow --dir="$ROOT" --target="$test_home" "${PACKAGES[@]}"

[ -L "$test_home/.bashrc" ]
[ -L "$test_home/.config/herdr/config.toml" ]
[ -L "$test_home/.pi/agent/extensions/webfetch" ]

HOME="$test_home" bash --noprofile --norc -c '
    source "$HOME/.bashrc"
    type mkcd >/dev/null
    type extract >/dev/null
    type venv_source >/dev/null
'

if ! command -v npm >/dev/null 2>&1 && [ -s "$HOME/.nvm/nvm.sh" ]; then
    # The Docker bootstrap runs as a child process, so reload NVM for this test process.
    # shellcheck source=/dev/null
    . "$HOME/.nvm/nvm.sh"
fi

echo "Installing and type-checking the Pi webfetch extension..."
command -v npm >/dev/null 2>&1 || { echo "npm is required for webfetch tests" >&2; exit 1; }
npm ci --prefix pi/.pi/agent/extensions/webfetch --no-audit --no-fund
npm run --prefix pi/.pi/agent/extensions/webfetch typecheck
cksum < pi/.pi/agent/extensions/webfetch/package-lock.json \
    > pi/.pi/agent/extensions/webfetch/node_modules/.dotfiles-lock-checksum

if command -v tmux >/dev/null 2>&1; then
    echo "Checking tmux configuration..."
    tmux_socket="dotfiles-test-$$"
    tmux -L "$tmux_socket" -f tmux/.tmux.conf new-session -d
    tmux -L "$tmux_socket" kill-server
fi

echo "All repository checks passed."
