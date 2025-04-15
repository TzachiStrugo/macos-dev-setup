#!/bin/bash

set -e

echo "🔧 Starting bootstrap process..."

# 1. Install Homebrew if not present
if ! command -v brew &> /dev/null; then
  echo "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "✅ Homebrew already installed."
fi

# 2. Add brew to PATH for the current session
if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
  echo "➕ Adding Homebrew to PATH for current session..."
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew already in PATH."
fi

# 3. Install Zsh (modern version) if not already installed via brew
if ! brew list zsh &>/dev/null; then
  echo "📦 Installing latest Zsh via Homebrew..."
  brew install zsh
else
  echo "✅ Zsh already installed via Homebrew."
fi

# 4. Change default shell to Homebrew Zsh (only if needed)
if [ "$SHELL" != "/opt/homebrew/bin/zsh" ]; then
  echo "🔁 Switching default shell to Homebrew Zsh..."
  chsh -s /opt/homebrew/bin/zsh
else
  echo "✅ Default shell is already Homebrew Zsh. Skipping shell change."
fi

# 5. Add brew shellenv to .zprofile if not already added
if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
  echo "➕ Updating ~/.zprofile to include Homebrew..."
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
else
  echo "✅ ~/.zprofile already configures Homebrew."
fi

echo ""
echo "🎉 Bootstrap completed!"
echo "👉 Restart your terminal to apply shell changes if needed."
