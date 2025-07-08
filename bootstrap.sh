#!/usr/bin/env bash

set -e  # Exit on error

echo "🚀 Setting up dotfiles environment..."

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
brew install --cask font-jetbrainsmono-nerd-font

echo "🔧 Installing essential development tools..."
brew install htop
brew install neovim
brew install nmap
brew install nvm
brew install pyenv
brew install starship
brew install tmux
brew install wget

echo "🔗 Installing GNU Stow for dotfiles management..."
brew install stow

echo "✨ Installing modern CLI tools..."
brew install fzf          # Fuzzy finder
brew install eza          # Better ls
brew install bat          # Better cat
brew install fd           # Better find
brew install ripgrep      # Better grep

echo "📦 Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

echo "🔗 Installing dotfiles with Stow..."
if [ -d "$HOME/dotfiles" ] && [ "$(pwd)" = "$HOME/dotfiles" ]; then
    stow bash shell zsh tmux vim misc
    echo "✅ Dotfiles installed successfully!"
else
    echo "⚠️  Please run this script from your dotfiles directory (~/dotfiles)"
    echo "   After cloning, run: cd ~/dotfiles && ./bootstrap.sh"
fi

echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Configure Starship: https://starship.rs/config/"
echo "3. Install Node.js: nvm install --lts"
echo "4. Install Python: pyenv install 3.11.0 && pyenv global 3.11.0"