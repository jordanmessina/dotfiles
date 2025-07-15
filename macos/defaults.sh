#!/usr/bin/env bash

# macOS System Defaults Configuration
# Run this script to apply macOS-specific system defaults

set -e

echo "⚙️ Configuring macOS system defaults..."

# Disable press-and-hold for keys in favor of key repeat
# This is needed for vim mode to work properly in apps like VSCode and Windsurf
echo "  • Disabling press-and-hold for keys (enables key repeat for vim mode in VSCode/Windsurf)"
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

echo "✅ macOS defaults applied successfully!"
echo "💡 Note: Some changes may require logging out and back in to take effect."