#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=(bash shell zsh tmux vim nvim misc starship ghostty pi herdr)
FORK_AGENT_PACKAGE="git:github.com/jordanmessina/pi-fork-agent@c767e3f2324d0b291c113965b41f4ab24621b5ca"
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
mkdir -p "$test_home/.config/ghostty" "$test_home/.config/herdr" "$test_home/.pi"
stow --dir="$ROOT" --target="$test_home" "${PACKAGES[@]}"

[ -L "$test_home/.bashrc" ]
[ -L "$test_home/.config/ghostty/config" ]
grep -Eq '^shell-integration-features = .*ssh-terminfo' \
    "$test_home/.config/ghostty/config"
[ -L "$test_home/.config/herdr/config.toml" ]
[ -L "$test_home/.pi/web-search.json" ]
[ ! -e "$test_home/.pi/agent/extensions/fork-agent" ]
grep -Fqx "$FORK_AGENT_PACKAGE" PiPackages
for network in \
    127.0.0.0/8 10.0.0.0/8 100.64.0.0/10 172.16.0.0/12 \
    192.168.0.0/16 ::1/128 fc00::/7 fe80::/10; do
    grep -Fq "\"$network\"" "$test_home/.pi/web-search.json"
done

HOME="$test_home" bash --noprofile --norc -c '
    source "$HOME/.bashrc"
    type mkcd >/dev/null
    type extract >/dev/null
    type venv_source >/dev/null
'

if command -v tmux >/dev/null 2>&1; then
    echo "Checking tmux configuration..."
    tmux_socket="dotfiles-test-$$"
    tmux -L "$tmux_socket" -f tmux/.tmux.conf new-session -d
    tmux -L "$tmux_socket" kill-server
fi

echo "All repository checks passed."
