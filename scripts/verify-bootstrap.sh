#!/usr/bin/env bash

set -Eeuo pipefail

export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

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

opencode_version="$(opencode --version)"
opencode_version="${opencode_version##* }"
opencode_version="${opencode_version#v}"
case "$opencode_version" in
    2.*) ;;
    *)
        echo "The installed OpenCode is not v2: $opencode_version" >&2
        exit 1
        ;;
esac
echo "Verified OpenCode v$opencode_version"
pi_version="$(pi --version)"
echo "Verified Pi $pi_version"

while IFS= read -r package || [ -n "$package" ]; do
    case "$package" in
        ""|\#*) continue ;;
    esac
    if ! pi list | grep -Fqx "  $package"; then
        echo "Missing expected Pi package: $package" >&2
        exit 1
    fi
done < "$(dirname "${BASH_SOURCE[0]}")/../PiPackages"

if ! ANTHROPIC_API_KEY=pi-bootstrap-smoke-test \
    pi --offline --no-session --print </dev/null; then
    echo "Pi failed to start with installed extensions enabled" >&2
    exit 1
fi

# shellcheck source=/dev/null
. "$HOME/.nvm/nvm.sh"
if [ "$(nvm current)" != "$(nvm version 'lts/*')" ]; then
    echo "The active Node.js version is not the latest installed LTS" >&2
    exit 1
fi

[ -L "$HOME/.config/nvim" ]
[ -L "$HOME/.pi/web-search.json" ]
[ -d "$HOME/.vim/bundle/Vundle.vim" ]

echo "Bootstrap installation verification passed."
