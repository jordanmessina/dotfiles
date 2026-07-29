#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_MACOS_DEFAULTS=0
SKIP_PACKAGES=0
STOW_ONLY=0

usage() {
    cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --macos-defaults  Apply the macOS defaults in macos/defaults.sh
  --skip-packages   Skip the Homebrew/apt package installation step
  --stow-only       Only back up conflicts and link dotfiles
  -h, --help        Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --macos-defaults)
            APPLY_MACOS_DEFAULTS=1
            ;;
        --skip-packages)
            SKIP_PACKAGES=1
            ;;
        --stow-only)
            STOW_ONLY=1
            SKIP_PACKAGES=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux) OS="linux" ;;
    *)
        echo "❌ Unsupported operating system: $(uname -s)" >&2
        exit 1
        ;;
esac

export PATH="$HOME/.local/bin:$PATH"

echo "🚀 Setting up dotfiles environment..."
echo "🖥️  Detected OS: $OS"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "❌ Required command not found: $1" >&2
        return 1
    fi
}

install_macos_packages() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "❌ Homebrew not found. Install it first:" >&2
        # shellcheck disable=SC2016
        echo '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >&2
        exit 1
    fi

    echo "📦 Updating Homebrew..."
    brew update

    echo "📦 Installing missing packages from Brewfile..."
    # Bootstrap should converge on the declared tools without upgrading the
    # rest of an existing Homebrew installation. Sequential jobs also avoid
    # lock contention between related formulae such as Neovim/tree-sitter.
    brew bundle --no-upgrade --jobs=1 --file="$DOTFILES_DIR/Brewfile"
}

install_linux_tree_sitter() {
    local tree_sitter_version="v0.25.10"
    local asset_arch=""
    local tmp_dir=""

    if command -v tree-sitter >/dev/null 2>&1; then
        echo "✅ tree-sitter is already installed"
        return
    fi

    case "$(uname -m)" in
        x86_64|amd64) asset_arch="x64" ;;
        aarch64|arm64) asset_arch="arm64" ;;
        *)
            echo "❌ Unsupported architecture for tree-sitter: $(uname -m)" >&2
            return 1
            ;;
    esac

    echo "🌳 Installing tree-sitter CLI for LazyVim..."
    tmp_dir="$(mktemp -d)"
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/${tree_sitter_version}/tree-sitter-linux-${asset_arch}.gz" -o "$tmp_dir/tree-sitter.gz"
    gunzip -c "$tmp_dir/tree-sitter.gz" > "$HOME/.local/bin/tree-sitter"
    chmod +x "$HOME/.local/bin/tree-sitter"
    rm -rf "$tmp_dir"
}

version_at_least() {
    # Linux bootstrap has sort -V through coreutils.
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n 1)" = "$1" ]
}

install_linux_neovim() {
    local required_version="0.11.2"
    local current_version=""
    local asset_arch=""
    local tmp_dir=""

    if command -v nvim >/dev/null 2>&1; then
        current_version="$(nvim --version | head -n 1)"
        current_version="${current_version#NVIM v}"
        current_version="${current_version%% *}"
    fi

    if [ -n "$current_version" ] && version_at_least "$required_version" "$current_version"; then
        echo "✅ Neovim $current_version is already installed"
        return
    fi

    case "$(uname -m)" in
        x86_64|amd64) asset_arch="x86_64" ;;
        aarch64|arm64) asset_arch="arm64" ;;
        *)
            echo "❌ Unsupported architecture for Neovim: $(uname -m)" >&2
            return 1
            ;;
    esac

    echo "📝 Installing Neovim >= $required_version for LazyVim..."
    tmp_dir="$(mktemp -d)"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${asset_arch}.tar.gz" -o "$tmp_dir/nvim.tar.gz"
    tar -xzf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"
    rm -rf "$HOME/.local/nvim"
    mv "$tmp_dir/nvim-linux-${asset_arch}" "$HOME/.local/nvim"
    ln -sfn "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmp_dir"
}

install_linux_packages() {
    local apt_install=(sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y)

    echo "📦 Updating apt package lists..."
    sudo apt-get update

    echo "📦 Installing Linux development packages..."
    "${apt_install[@]}" \
        htop vim nmap tmux wget curl git unzip tree fontconfig \
        build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev \
        libxmlsec1-dev libffi-dev liblzma-dev \
        stow fzf bat fd-find ripgrep pipx gpg \
        zsh lsof shellcheck xclip

    mkdir -p "$HOME/.local/bin"
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        ln -sfn /usr/bin/batcat "$HOME/.local/bin/bat"
    fi
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        ln -sfn /usr/bin/fdfind "$HOME/.local/bin/fd"
    fi

    if ! command -v eza >/dev/null 2>&1; then
        echo "✨ Installing eza..."
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update
        "${apt_install[@]}" eza
    fi

    install_linux_neovim
    install_linux_tree_sitter
    install_linux_lazygit
    install_linux_font
    install_linux_pyenv
    install_linux_starship
}

install_linux_lazygit() {
    local lazygit_version="0.61.1"
    local asset_arch=""
    local tmp_dir=""

    if command -v lazygit >/dev/null 2>&1; then
        echo "✅ lazygit is already installed"
        return
    fi

    case "$(uname -m)" in
        x86_64|amd64) asset_arch="x86_64" ;;
        aarch64|arm64) asset_arch="arm64" ;;
        *)
            echo "❌ Unsupported architecture for lazygit: $(uname -m)" >&2
            return 1
            ;;
    esac

    echo "✨ Installing lazygit..."
    tmp_dir="$(mktemp -d)"
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_${asset_arch}.tar.gz" -o "$tmp_dir/lazygit.tar.gz"
    tar -xzf "$tmp_dir/lazygit.tar.gz" -C "$tmp_dir" lazygit
    install -m 0755 "$tmp_dir/lazygit" "$HOME/.local/bin/lazygit"
    rm -rf "$tmp_dir"
}

install_linux_font() {
    local font_dir="$HOME/.local/share/fonts"
    local font_version="v3.0.2"
    local tmp_zip=""

    if find "$font_dir" -maxdepth 1 -name 'JetBrainsMono*NerdFont*.ttf' -print -quit 2>/dev/null | grep -q .; then
        echo "✅ JetBrains Mono Nerd Font is already installed"
        return
    fi

    echo "🎨 Installing JetBrains Mono Nerd Font..."
    mkdir -p "$font_dir"
    tmp_zip="$(mktemp)"
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${font_version}/JetBrainsMono.zip" -o "$tmp_zip"
    unzip -oq "$tmp_zip" -d "$font_dir"
    rm -f "$tmp_zip"
    fc-cache -f
}

install_linux_pyenv() {
    if [ -d "$HOME/.pyenv" ]; then
        echo "✅ pyenv is already installed"
        return
    fi

    echo "🐍 Installing pyenv..."
    curl -fsSL https://pyenv.run | bash
}

install_linux_starship() {
    if command -v starship >/dev/null 2>&1; then
        echo "✅ Starship is already installed"
        return
    fi

    echo "🌟 Installing Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
}

install_nvm_and_node() {
    if [ -z "${NVM_DIR-}" ]; then
        if [ -n "${XDG_CONFIG_HOME-}" ]; then
            NVM_DIR="$XDG_CONFIG_HOME/nvm"
        else
            NVM_DIR="$HOME/.nvm"
        fi
    fi
    export NVM_DIR

    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "📦 Installing NVM..."
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    else
        echo "✅ NVM is already installed"
    fi

    # nvm is a shell function, so load it explicitly in this bootstrap process.
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"

    echo "📦 Installing the latest Node.js LTS release..."
    nvm install --lts
    nvm alias default 'lts/*'
    nvm use default
    hash -r
    echo "✅ Node.js $(node --version) and npm $(npm --version) are active"
}

install_opencode() {
    if command -v opencode >/dev/null 2>&1 || [ -x "$HOME/.opencode/bin/opencode" ]; then
        echo "✅ OpenCode is already installed"
        return
    fi

    echo "📦 Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
    hash -r
}

install_pi() {
    if command -v pi >/dev/null 2>&1; then
        echo "✅ Pi is already installed"
        return
    fi

    # The curl installer opens /dev/tty and renders an interactive full-screen
    # flow. This is the same npm installation command it ultimately executes,
    # but remains non-interactive and uses NVM's writable global prefix.
    echo "📦 Installing Pi..."
    npm install -g --ignore-scripts --min-release-age=0 --no-fund --no-audit \
        @earendil-works/pi-coding-agent
    hash -r
}

install_pi_packages() {
    local manifest="$DOTFILES_DIR/PiPackages"
    local installed_packages=""
    local package=""

    require_command pi
    [ -f "$manifest" ] || { echo "❌ Pi package manifest not found: $manifest" >&2; return 1; }
    installed_packages="$(pi list 2>/dev/null || true)"

    while IFS= read -r package || [ -n "$package" ]; do
        case "$package" in
            ""|\#*) continue ;;
        esac

        if printf '%s\n' "$installed_packages" | grep -Fqx "  $package"; then
            echo "✅ Pi package is already installed: $package"
            continue
        fi

        echo "📦 Installing Pi package: $package"
        pi install "$package"
        installed_packages="${installed_packages}"$'\n'"  $package"
    done < "$manifest"
}

install_herdr() {
    if command -v herdr >/dev/null 2>&1; then
        echo "✅ HerdR is already installed"
        return
    fi

    echo "🐑 Installing HerdR..."
    if [ "$OS" = "macos" ]; then
        require_command brew
        brew install herdr
    else
        curl -fsSL https://herdr.dev/install.sh | sh
    fi
    hash -r
}

install_vundle() {
    if [ -d "$HOME/.vim/bundle/Vundle.vim" ]; then
        echo "✅ Vundle is already installed"
        return
    fi

    echo "📦 Installing Vundle..."
    git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
}

install_python_tools() {
    if ! command -v pipx >/dev/null 2>&1; then
        echo "⚠️  pipx not found; skipping Python tools"
        return
    fi

    pipx ensurepath >/dev/null
    for package in black flake8; do
        if pipx list --short 2>/dev/null | grep -qx "$package"; then
            echo "✅ $package is already installed"
        else
            echo "🐍 Installing $package with pipx..."
            pipx install "$package"
        fi
    done
}

backup_conflicts() {
    local backup_dir="$1"
    local file=""
    local relative=""
    local conflicts=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
        "$HOME/.vimrc"
        "$HOME/.hushlogin"
        "$HOME/.config/starship.toml"
        "$HOME/.config/nvim"
        "$HOME/.config/herdr/config.toml"
    )

    for file in "${conflicts[@]}"; do
        if [ ! -e "$file" ] && [ ! -L "$file" ]; then
            continue
        fi

        if [ -L "$file" ]; then
            case "$(readlink "$file")" in
                *dotfiles/*) continue ;;
            esac
        fi

        relative="${file#"$HOME"/}"
        mkdir -p "$backup_dir/$(dirname "$relative")"
        echo "  Backing up ~/$relative"
        mv "$file" "$backup_dir/$relative"
    done
}

stow_dotfiles() {
    local backup_dir=""
    local packages=(bash shell zsh tmux vim nvim misc starship pi herdr)
    backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

    require_command stow
    mkdir -p "$backup_dir" "$HOME/.config" "$HOME/.config/herdr" "$HOME/.pi/agent/extensions"

    echo "📋 Backing up conflicting dotfiles..."
    backup_conflicts "$backup_dir"

    echo "🔗 Stowing dotfiles packages..."
    (
        cd "$DOTFILES_DIR"
        stow --restow --target="$HOME" "${packages[@]}"
    )

    if find "$backup_dir" -mindepth 1 -print -quit | grep -q .; then
        echo "📁 Original files backed up to: $backup_dir"
    else
        rmdir "$backup_dir"
    fi
}

install_webfetch_dependencies() {
    local extension_dir="$DOTFILES_DIR/pi/.pi/agent/extensions/webfetch"
    local stamp_file="$extension_dir/node_modules/.dotfiles-lock-checksum"
    local lock_checksum=""

    require_command npm
    lock_checksum="$(cksum < "$extension_dir/package-lock.json")"

    if [ -f "$stamp_file" ] && [ "$(cat "$stamp_file")" = "$lock_checksum" ] && (cd "$extension_dir" && npm ls --depth=0 >/dev/null 2>&1); then
        echo "✅ Pi webfetch dependencies are up to date"
        return
    fi

    echo "📦 Installing Pi webfetch dependencies..."
    (
        cd "$extension_dir"
        npm ci --no-audit --no-fund
        printf '%s\n' "$lock_checksum" > node_modules/.dotfiles-lock-checksum
        npm run typecheck
    )
}

install_vim_plugins() {
    if ! command -v vim >/dev/null 2>&1; then
        echo "⚠️  Vim not found; skipping Vim plugins"
        return
    fi

    echo "📦 Installing Vim plugins..."
    vim -es -u "$HOME/.vimrc" +PluginInstall +qall
}

if [ "$STOW_ONLY" -eq 0 ]; then
    if [ "$SKIP_PACKAGES" -eq 0 ]; then
        if [ "$OS" = "macos" ]; then
            install_macos_packages
        else
            install_linux_packages
        fi
    else
        echo "📦 Skipping OS package installation"
    fi

    mkdir -p "$HOME/.local/bin"
    install_nvm_and_node
    install_opencode
    install_pi
    install_pi_packages
    install_herdr
    install_vundle
    install_python_tools
fi

stow_dotfiles

if [ "$STOW_ONLY" -eq 0 ]; then
    install_webfetch_dependencies
    install_vim_plugins
fi

if [ "$OS" = "macos" ] && [ "$APPLY_MACOS_DEFAULTS" -eq 1 ]; then
    "$DOTFILES_DIR/macos/defaults.sh"
elif [ "$OS" = "macos" ]; then
    echo "⚙️  Skipping macOS defaults. Use --macos-defaults to apply them."
fi

echo "🎉 Setup complete!"
echo
echo "Next steps:"
echo "1. Restart your terminal or source your shell configuration."
echo "2. Run 'nvim' once to let LazyVim install its plugins, then run :LazyHealth."
echo "3. Install a Python version if needed: pyenv install 3.11.0 && pyenv global 3.11.0"
if [ "$OS" = "linux" ]; then
    echo "4. To make Zsh your login shell, run: chsh -s \"$(command -v zsh)\""
fi
