#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
for file in "${SHELL_FILES[@]}" scripts/test.sh scripts/test-docker.sh scripts/verify-bootstrap.sh; do
    bash -n "$file"
done

if command -v zsh >/dev/null 2>&1; then
    echo "Checking Zsh syntax..."
    for file in zsh/.zshrc shell/.shell/exports shell/.shell/aliases \
        shell/.shell/functions shell/.shell/keybindings shell/.shell/completions; do
        zsh -n "$file"
    done
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
HOME="$test_home" ./bootstrap.sh --stow-only
[ -f "$test_home/.shell.local" ]
[ ! -L "$test_home/.shell.local" ]
[ ! -s "$test_home/.shell.local" ]
printf '%s\n' 'export DOTFILES_LOCAL_TEST=loaded' > "$test_home/.shell.local"
HOME="$test_home" ./bootstrap.sh --stow-only

[ -L "$test_home/.bashrc" ]
[ -L "$test_home/.config/ghostty/config" ]
grep -Fxq 'font-family = MonoLisaCode' "$test_home/.config/ghostty/config"
grep -Eq '^shell-integration-features = .*ssh-terminfo' \
    "$test_home/.config/ghostty/config"
[ -L "$test_home/.config/rex/init.lua" ]
if command -v rex >/dev/null 2>&1; then
    rex config check "$test_home/.config/rex/init.lua"
fi
[ -L "$test_home/.pi/web-search.json" ]
grep -Fqx 'npm:pi-web-access' PiPackages
for network in \
    127.0.0.0/8 10.0.0.0/8 100.64.0.0/10 172.16.0.0/12 \
    192.168.0.0/16 ::1/128 fc00::/7 fe80::/10; do
    grep -Fq "\"$network\"" "$test_home/.pi/web-search.json"
done

HOME="$test_home" bash --noprofile --norc -c '
    source "$HOME/.bashrc"
    set -e
    type mkcd >/dev/null
    type extract >/dev/null
    type venv_source >/dev/null
    [ "$DOTFILES_LOCAL_TEST" = loaded ]
'
if command -v zsh >/dev/null 2>&1; then
    HOME="$test_home" zsh -f -c 'source "$HOME/.zshrc" && [ "$DOTFILES_LOCAL_TEST" = loaded ]'
fi

if command -v tmux >/dev/null 2>&1; then
    echo "Checking tmux configuration..."
    tmux_socket="dotfiles-test-$$"
    tmux -L "$tmux_socket" -f tmux/.tmux.conf new-session -d
    tmux -L "$tmux_socket" kill-server
fi

echo "All repository checks passed."
