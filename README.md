# Dotfiles

A modern, modular dotfiles setup for macOS and Linux using GNU Stow for symlink management. This repository provides a comprehensive development environment configuration with cross-shell compatibility for both bash and zsh.

## Features

- **Modular Structure**: Organized by application with GNU Stow for clean symlink management
- **Cross-Shell Compatibility**: Shared configurations work with both bash and zsh
- **Modern Tools**: Includes Starship prompt, pyenv, nvm, and useful utility functions
- **Selective Installation**: Install only the packages you need
- **Version Controlled**: Track changes and sync across multiple machines

## Quick Start

```bash
# Clone the repository
git clone git@github.com:jordanmessina/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install dependencies and link dotfiles
./bootstrap.sh
```

On macOS, use `./bootstrap.sh --macos-defaults` instead if you also want system defaults applied.

## Requirements

### macOS
- [Homebrew](https://brew.sh/)
- GNU Stow (installed by bootstrap script)

### Linux (Ubuntu/Debian)
- `apt-get` package manager
- `sudo` privileges
- GNU Stow (installed by bootstrap script)

## Repository Structure

```
dotfiles/
├── bash/                 # Bash shell configuration
│   ├── .bashrc          # Interactive shell settings
│   └── .bash_profile    # Login shell configuration
├── zsh/                 # Zsh shell configuration
│   └── .zshrc           # Interactive shell settings
├── shell/               # Shared shell utilities
│   └── .shell/
│       ├── aliases      # Common aliases and shortcuts
│       ├── exports      # Environment variables and tool setup
│       └── functions    # Utility functions
├── tmux/                # Terminal multiplexer
│   └── .tmux.conf       # Tmux configuration
├── vim/                 # Vim editor
│   └── .vimrc           # Vim configuration with plugins
├── misc/                # Miscellaneous files
│   └── .hushlogin       # Suppress login messages
├── bootstrap.sh         # Automated setup script
└── .stow-local-ignore   # Files to exclude from stowing
```

## Installation

### Option 1: Full Setup (Recommended)

```bash
# Clone and setup everything
git clone git@github.com:jordanmessina/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

To apply macOS system defaults during setup, run `./bootstrap.sh --macos-defaults` instead.

### Option 2: Manual Installation

1. **Install dependencies**:
   ```bash
   brew install stow
   # See bootstrap.sh for full list of tools
   ```

2. **Install selected packages**:
   ```bash
   cd ~/dotfiles
   stow shell          # Essential shared utilities
   stow zsh            # Zsh configuration
   stow tmux           # Terminal multiplexer
   stow starship       # Starship prompt configuration
   # Install only what you need
   ```

### Option 3: Selective Installation

```bash
# Install only shell and zsh for a minimal setup
stow shell zsh

# Add tmux and vim later
stow tmux vim
```

## What Gets Installed

### Development Tools (via bootstrap.sh)

**macOS (via Homebrew):**
- **Core packages**: htop, vim, nmap, pyenv, starship, tmux, wget, tree, stow
- **Modern CLI tools**: fzf, eza, bat, fd, ripgrep
- **Fonts**: JetBrains Mono Nerd Font (for Starship prompt)
- **NVM**: Node Version Manager for Node.js versions
- **OpenCode**: Installed via official installer

**Linux (via apt-get):**
- **Core packages**: htop, vim, nmap, tmux, wget, curl, git, tree, stow
- **Build tools**: build-essential, various development libraries
- **Modern CLI tools**: fzf, eza, bat, fd, ripgrep (with symlinks for compatibility)
- **Fonts**: JetBrains Mono Nerd Font (downloaded directly)
- **pyenv**: Installed via official installer
- **Starship**: Installed via official installer
- **NVM**: Node Version Manager for Node.js versions
- **OpenCode**: Installed via official installer

### Shell Configuration
- **Starship**: Modern, fast prompt with git integration
- **pyenv**: Python version management
- **NVM**: Node.js version management
- **OpenCode**: CLI path setup
- **Aliases**: Common shortcuts for navigation and git
- **Functions**: Utility functions for development

## Available Functions

The `shell` package provides these utility functions:

### Navigation & Files
- `mkcd <dir>` - Create directory and change into it
- `up [n]` - Navigate up n directories (default: 1)
- `extract <file>` - Universal archive extraction
- `serve [port]` - Quick HTTP server (default port: 8000)

### Python Development
- `mkvenv` - Create and activate Python virtual environment in `.venv`

### System Utilities
- `killport <port>` - Kill process running on specified port
- `myip` - Show internal and external IP addresses
- `ls/ll/la` - Enhanced with `eza` if available
- `cat` - Enhanced with `bat` if available

### Git Utilities (requires fzf)
- `gadd` - Interactive git add with preview
- `gbr` - Interactive git branch switcher

### Aliases
- `..`, `...`, `....` - Navigate up directories
- `g` - Git shorthand
- `show`/`hide` - Show/hide hidden files in Finder (macOS)

## Shell Compatibility

This setup works with both bash and zsh across platforms:

- **macOS Default**: Uses zsh by default (since Catalina)
- **Linux Default**: Usually bash, but zsh fully supported
- **Cross-Platform**: All functions and aliases work on both macOS and Linux
- **Shared Configuration**: Common settings in `~/.shell/`
- **Shell-Specific**: Custom configurations in respective packages
- **OS-Specific**: Platform-specific commands (like macOS Finder aliases) are conditionally loaded

## Customization

### Adding New Tools

1. **Add to bootstrap.sh**:
   ```bash
   brew install your-tool
   ```

2. **Create configuration package**:
   ```bash
   mkdir your-tool
   # Add dotfiles with proper structure
   ```

3. **Install with stow**:
   ```bash
   stow your-tool
   ```

### Modifying Existing Configuration

Simply edit the files in the package directories. Changes are immediately reflected since they're symlinked.

### Adding Shell Functions

Add new functions to `shell/.shell/functions`:

```bash
# Your custom function
myfunction() {
    echo "Hello from custom function"
}
```

## Troubleshooting

### Stow Conflicts
If stow reports conflicts, you may have existing files:
```bash
# Backup existing files
mv ~/.bashrc ~/.bashrc.backup
# Then re-run stow
stow bash
```

### Missing Tools
If functions fail due to missing tools:

**macOS:**
```bash
brew install fzf eza bat fd ripgrep
```

**Linux:**
```bash
# Most tools are installed by bootstrap.sh, but if needed:
sudo apt-get install fzf bat fd-find ripgrep
```

### Shell Not Loading Configuration
Ensure your terminal is running the correct shell:
```bash
echo $SHELL
# Should show /bin/zsh or /bin/bash
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your configurations
4. Test on a clean system
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [GNU Stow](https://www.gnu.org/software/stow/) for symlink management
- [Starship](https://starship.rs/) for the amazing prompt
- The dotfiles community for inspiration and best practices
