#!/usr/bin/env bash

set -e  # Exit on error

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

    echo "⬆️ Upgrading installed packages..."
    brew upgrade

    echo "🎨 Installing Nerd Font (required for Starship)..."
    brew install --cask font-jetbrains-mono-nerd-font

    echo "🔧 Installing essential development tools..."
    brew install htop
    brew install vim
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
    
    echo "🐍 Installing pipx for Python package management..."
    brew install pipx
}

# Function to install packages on Linux
install_linux_packages() {
    echo "📦 Updating package lists..."
    sudo apt-get update

    echo "⬆️ Upgrading installed packages..."
    sudo apt-get upgrade -y

    echo "🔧 Installing essential development tools..."
    sudo apt-get install -y \
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
    sudo apt-get install -y stow

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
        sudo apt-get install -y gpg
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update
        sudo apt-get install -y eza
    fi

    # Install bat (better cat)
    sudo apt-get install -y bat
    # Create symlink for bat if it's installed as batcat
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/batcat ~/.local/bin/bat
    fi

    # Install fd (better find)
    sudo apt-get install -y fd-find
    # Create symlink for fd if it's installed as fdfind
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/fdfind ~/.local/bin/fd
    fi

    # Install ripgrep (better grep)
    sudo apt-get install -y ripgrep
    
    echo "🐍 Installing pipx for Python package management..."
    sudo apt-get install -y pipx

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
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        echo "✅ Starship installed successfully"
    else
        echo "✅ Starship is already installed"
    fi
}

# Install packages based on OS
if [[ "$OS" == "macos" ]]; then
    install_macos_packages
    # Apply macOS-specific system defaults
    ./macos/defaults.sh
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
if [ -d "$HOME/dotfiles" ] && [ "$(pwd)" = "$HOME/dotfiles" ]; then
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
    )
    
    # Move conflicting files to backup
    for file in "${conflicts[@]}"; do
        if [ -f "$file" ] && [ ! -L "$file" ]; then
            echo "  Backing up $(basename "$file")"
            mv "$file" "$backup_dir/"
        fi
    done
    
    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Now stow the packages
    echo "🔗 Stowing dotfiles packages..."
    stow bash shell zsh tmux vim misc starship
    echo "✅ Dotfiles installed successfully!"
    
    # Install vim plugins
    echo "📦 Installing Vim plugins..."
    vim +PluginInstall +qall
    echo "✅ Vim plugins installed successfully!"
    
    if [ -d "$backup_dir" ] && [ "$(ls -A "$backup_dir")" ]; then
        echo "📁 Original files backed up to: $backup_dir"
    else
        # Remove empty backup directory
        rmdir "$backup_dir" 2>/dev/null || true
    fi
else
    echo "⚠️  Please run this script from your dotfiles directory (~/dotfiles)"
    echo "   After cloning, run: cd ~/dotfiles && ./bootstrap.sh"
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
