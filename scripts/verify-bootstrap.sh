#!/usr/bin/env bash

set -Eeuo pipefail

export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

FORK_AGENT_PACKAGE="git:github.com/jordanmessina/pi-fork-agent@3fcf9e666e3a54a9f540e122de088c59120d5f8e"

if ! command -v node >/dev/null 2>&1 && [ -s "$HOME/.nvm/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.nvm/nvm.sh"
fi

commands=(
    bat
    black
    eza
    fd
    flake8
    herdr
    lazygit
    lsof
    node
    npm
    nvim
    opencode
    pi
    starship
    stow
    tree-sitter
    zsh
)

for command_name in "${commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing expected bootstrap command: $command_name" >&2
        exit 1
    fi
done

for package in npm:pi-mcp-adapter npm:pi-web-access "$FORK_AGENT_PACKAGE"; do
    if ! pi list | grep -Fqx "  $package"; then
        echo "Missing expected Pi package: $package" >&2
        exit 1
    fi
done

# shellcheck source=/dev/null
. "$HOME/.nvm/nvm.sh"
if [ "$(nvm current)" != "$(nvm version 'lts/*')" ]; then
    echo "The active Node.js version is not the latest installed LTS" >&2
    exit 1
fi

[ -L "$HOME/.config/herdr/config.toml" ]
[ -L "$HOME/.config/nvim" ]
[ ! -e "$HOME/.pi/agent/extensions/fork-agent" ]
[ -L "$HOME/.pi/web-search.json" ]
[ -d "$HOME/.vim/bundle/Vundle.vim" ]

echo "Bootstrap installation verification passed."
