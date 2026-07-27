#!/usr/bin/env bash

set -Eeuo pipefail

export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

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

# shellcheck source=/dev/null
. "$HOME/.nvm/nvm.sh"
if [ "$(nvm current)" != "$(nvm version 'lts/*')" ]; then
    echo "The active Node.js version is not the latest installed LTS" >&2
    exit 1
fi

[ -L "$HOME/.config/herdr/config.toml" ]
[ -L "$HOME/.config/nvim" ]
[ -L "$HOME/.pi/agent/extensions/webfetch" ]
[ -d "$HOME/.vim/bundle/Vundle.vim" ]

npm ls --prefix "$HOME/.pi/agent/extensions/webfetch" --depth=0 >/dev/null
npm run --prefix "$HOME/.pi/agent/extensions/webfetch" typecheck >/dev/null

echo "Bootstrap installation verification passed."
