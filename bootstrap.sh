#!/usr/bin/env bash

set -e  # Exit on error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_MACOS_DEFAULTS=0

for arg in "$@"; do
    case "$arg" in
        --macos-defaults)
            APPLY_MACOS_DEFAULTS=1
            ;;
        *)
            echo "❌ Unknown option: $arg"
            echo "Usage: ./bootstrap.sh [--macos-defaults]"
            exit 1
            ;;
    esac
done

echo "🚀 Setting up dotfiles environment..."

# Detect operating system
OS=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    echo "❌ Unsupported operating system: $OSTYPE"
    echo "This script supports macOS and Linux only."
    exit 1
fi

echo "🖥️  Detected OS: $OS"

# Function to install packages on macOS
install_macos_packages() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    echo "📦 Updating Homebrew..."
    brew update

    echo "🎨 Installing Nerd Font (required for Starship)..."
    brew install --cask font-jetbrains-mono-nerd-font

    echo "🔧 Installing essential development tools..."
    brew install htop
    brew install vim
    brew install neovim
    brew install nmap
    brew install pyenv
    brew install starship
    brew install tmux
    brew install wget
    brew install tree

    echo "🔗 Installing GNU Stow for dotfiles management..."
    brew install stow

    echo "✨ Installing modern CLI tools..."
    brew install fzf          # Fuzzy finder
    brew install eza          # Better ls
    brew install bat          # Better cat
    brew install fd           # Better find
    brew install ripgrep      # Better grep
    brew install lazygit      # Git TUI used by LazyVim
    brew install tree-sitter  # Parser generator used by LazyVim
    
    echo "🐍 Installing pipx for Python package management..."
    brew install pipx
}

# Function to install tree-sitter CLI on Linux
install_linux_tree_sitter() {
    local tree_sitter_version="v0.25.10"

    if command -v tree-sitter &> /dev/null; then
        echo "✅ tree-sitter is already installed"
        return 0
    fi

    echo "🌳 Installing tree-sitter CLI for LazyVim..."
    local asset_arch=""
    case "$(uname -m)" in
        x86_64|amd64)
            asset_arch="x64"
            ;;
        aarch64|arm64)
            asset_arch="arm64"
            ;;
        *)
            echo "❌ Unsupported architecture for tree-sitter release: $(uname -m)"
            return 1
            ;;
    esac

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    mkdir -p "$HOME/.local/bin"
    curl -L "https://github.com/tree-sitter/tree-sitter/releases/download/${tree_sitter_version}/tree-sitter-linux-${asset_arch}.gz" -o "$tmp_dir/tree-sitter.gz"
    gunzip -c "$tmp_dir/tree-sitter.gz" > "$HOME/.local/bin/tree-sitter"
    chmod +x "$HOME/.local/bin/tree-sitter"
    rm -rf "$tmp_dir"
    echo "✅ tree-sitter installed successfully"
}

# Function to install a recent Neovim release on Linux
install_linux_neovim() {
    local required_version="0.11.2"
    local current_version=""

    if command -v nvim &> /dev/null; then
        local version_line
        version_line="$(nvim --version | head -n 1)"
        current_version="${version_line#NVIM v}"
        current_version="${current_version%% *}"
    fi

    if [ -n "$current_version" ] && [ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n 1)" = "$required_version" ]; then
        echo "✅ Neovim $current_version is already installed"
        return 0
    fi

    echo "📝 Installing Neovim >= $required_version for LazyVim..."
    local asset_arch=""
    case "$(uname -m)" in
        x86_64|amd64)
            asset_arch="x86_64"
            ;;
        aarch64|arm64)
            asset_arch="arm64"
            ;;
        *)
            echo "❌ Unsupported architecture for Neovim release: $(uname -m)"
            return 1
            ;;
    esac

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    mkdir -p "$HOME/.local/bin"
    curl -L "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${asset_arch}.tar.gz" -o "$tmp_dir/nvim.tar.gz"
    tar -xzf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"
    rm -rf "$HOME/.local/nvim"
    mv "$tmp_dir/nvim-linux-${asset_arch}" "$HOME/.local/nvim"
    ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmp_dir"
    echo "✅ Neovim installed successfully"
}

# Function to install packages on Linux
install_linux_packages() {
    local apt_install=(sudo DEBIAN_FRONTEND=noninteractive apt-get install -y)

    echo "📦 Updating package lists..."
    sudo apt-get update

    echo "🔧 Installing essential development tools..."
    "${apt_install[@]}" \
        htop \
        vim \
        nmap \
        tmux \
        wget \
        curl \
        git \
        unzip \
        tree \
        fontconfig \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libffi-dev \
        liblzma-dev

    echo "🔗 Installing GNU Stow for dotfiles management..."
    "${apt_install[@]}" stow

    echo "✨ Installing modern CLI tools..."
    # Install fzf
    if [ ! -d "$HOME/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
        echo "✅ fzf installed successfully"
    elif ! command -v fzf &> /dev/null; then
        echo "fzf directory exists, running installer..."
        ~/.fzf/install --all
        echo "✅ fzf configured successfully"
    else
        echo "✅ fzf is already installed"
    fi

    # Install eza (better ls)
    if ! command -v eza &> /dev/null; then
        "${apt_install[@]}" gpg
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update
        "${apt_install[@]}" eza
    fi

    # Install bat (better cat)
    "${apt_install[@]}" bat
    # Create symlink for bat if it's installed as batcat
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/batcat ~/.local/bin/bat
    fi

    # Install fd (better find)
    "${apt_install[@]}" fd-find
    # Create symlink for fd if it's installed as fdfind
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/fdfind ~/.local/bin/fd
    fi

    # Install ripgrep (better grep)
    "${apt_install[@]}" ripgrep
    
    echo "🐍 Installing pipx for Python package management..."
    "${apt_install[@]}" pipx

    install_linux_neovim
    install_linux_tree_sitter

    echo "🎨 Installing Nerd Font (JetBrains Mono)..."
    # Download and install JetBrains Mono Nerd Font
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    if [ ! -f "$FONT_DIR/JetBrainsMono-Regular.ttf" ]; then
        echo "Downloading JetBrains Mono Nerd Font..."
        wget -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
        unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR"
        rm /tmp/JetBrainsMono.zip
        fc-cache -fv
        echo "✅ JetBrains Mono Nerd Font installed"
    else
        echo "✅ JetBrains Mono Nerd Font already installed"
    fi

    echo "🚀 Installing pyenv..."
    if [ ! -d "$HOME/.pyenv" ]; then
        curl https://pyenv.run | bash
        echo "✅ pyenv installed successfully"
    else
        echo "✅ pyenv is already installed"
    fi

    echo "🌟 Installing Starship..."
    if ! command -v starship &> /dev/null; then
        mkdir -p "$HOME/.local/bin"
        curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
        echo "✅ Starship installed successfully"
    else
        echo "✅ Starship is already installed"
    fi
}

# Install packages based on OS
if [[ "$OS" == "macos" ]]; then
    install_macos_packages
    if [[ "$APPLY_MACOS_DEFAULTS" -eq 1 ]]; then
        "$DOTFILES_DIR/macos/defaults.sh"
    else
        echo "⚙️ Skipping macOS defaults. Run ./bootstrap.sh --macos-defaults to apply them."
    fi
elif [[ "$OS" == "linux" ]]; then
    install_linux_packages
fi

echo "📦 Installing NVM..."
if [ -d "$HOME/.nvm" ] || command -v nvm &> /dev/null; then
    echo "✅ NVM is already installed"
else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    echo "✅ NVM installed successfully"
fi

echo "📦 Installing OpenCode..."
if command -v opencode &> /dev/null || [ -x "$HOME/.opencode/bin/opencode" ]; then
    echo "✅ OpenCode is already installed"
else
    curl -fsSL https://opencode.ai/install | bash
    echo "✅ OpenCode installed successfully"
fi

echo "📦 Installing Vundle for Vim plugin management..."
if [ -d "$HOME/.vim/bundle/Vundle.vim" ]; then
    echo "✅ Vundle is already installed"
else
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    echo "✅ Vundle installed successfully"
fi

echo "🐍 Installing Python development tools via pipx..."
if command -v pipx &> /dev/null; then
    # Ensure pipx path is available
    pipx ensurepath
    
    # Install black (code formatter)
    if ! pipx list | grep -q "black"; then
        echo "Installing black (Python code formatter)..."
        pipx install black
        echo "✅ black installed successfully"
    else
        echo "✅ black is already installed"
    fi
    
    # Install flake8 (linter)
    if ! pipx list | grep -q "flake8"; then
        echo "Installing flake8 (Python linter)..."
        pipx install flake8
        echo "✅ flake8 installed successfully"
    else
        echo "✅ flake8 is already installed"
    fi
else
    echo "⚠️  pipx not found, skipping Python tool installation"
fi

echo "🔗 Installing dotfiles with Stow..."
# Backup existing dotfiles that might conflict
echo "📋 Backing up existing dotfiles..."
backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

# List of files that might conflict
conflicts=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.zshrc"
    "$HOME/.tmux.conf"
    "$HOME/.vimrc"
    "$HOME/.hushlogin"
    "$HOME/.config/starship.toml"
    "$HOME/.config/nvim"
)

# Move conflicting files to backup
for file in "${conflicts[@]}"; do
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        echo "  Backing up $(basename "$file")"
        mv "$file" "$backup_dir/"
    fi
done

# Create .config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Now stow the packages
echo "🔗 Stowing dotfiles packages..."
(
    cd "$DOTFILES_DIR"
    stow --target="$HOME" bash shell zsh tmux vim nvim misc starship
)
echo "✅ Dotfiles installed successfully!"

# Install vim plugins
echo "📦 Installing Vim plugins..."
vim -es -u "$HOME/.vimrc" +PluginInstall +qall
echo "✅ Vim plugins installed successfully!"

if [ -d "$backup_dir" ] && [ "$(ls -A "$backup_dir")" ]; then
    echo "📁 Original files backed up to: $backup_dir"
else
    # Remove empty backup directory
    rmdir "$backup_dir" 2>/dev/null || true
fi

echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
if [[ "$OS" == "macos" ]]; then
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Configure Starship: https://starship.rs/config/"
    echo "3. Install Node.js: nvm install --lts"
    echo "4. Install Python: pyenv install 3.11.0 && pyenv global 3.11.0"
    echo "5. Python tools available: black (formatter), flake8 (linter)"
    echo "6. Vim plugins are ready! Use :PluginInstall in vim to add more"
elif [[ "$OS" == "linux" ]]; then
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Configure Starship: https://starship.rs/config/"
    echo "3. Install Node.js: nvm install --lts"
    echo "4. Install Python: pyenv install 3.11.0 && pyenv global 3.11.0"
    echo "5. Python tools available: black (formatter), flake8 (linter)"
    echo "6. Vim plugins are ready! Use :PluginInstall in vim to add more"
fi
