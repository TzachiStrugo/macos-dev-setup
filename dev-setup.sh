#!/bin/bash

set -e

echo ""
echo "  🔧 Starting MAC Software Installation OR Uninstallation..."
echo ""

# Function to prompt user for action
ask_choice() {
  echo "$1"
  select opt in "$2" "Skip" "Abort"; do
    case $opt in
      "$2")
        echo "  ✅ Proceeding with $2 operation."
        return 0
        ;;
      "Skip")
        echo "  ⏩ Skipping $2 operation."
        return 1
        ;;
      "Abort")
        echo "  ❌ Aborting the process."
        exit 1
        ;;
      *)
        echo "Invalid option. Please select 1 (Install), 2 (Skip), or 3 (Abort)."
        ;;
    esac
  done
}

update_homebrew() {

  echo "  🔄 Updating Homebrew..."
  brew update && brew upgrade && brew cleanup
}

# Function to uninstall Visual Studio Code and related components
uninstall_vscode() {
  echo ""
  echo "  🧹 Uninstalling Visual Studio Code..."
  brew uninstall --cask visual-studio-code
  echo "  ✅ Visual Studio Code uninstalled."

  echo ""
  echo "  Removing 'code' command from terminal..."
  sudo rm /usr/local/bin/code
  echo "  ✅ 'code' command removed from terminal."

  echo ""
  echo "  Removing Visual Studio Code from Applications folder..."
  sudo rm -rf /Applications/Visual\ Studio\ Code.app
  echo "  ✅ Visual Studio Code removed from Applications folder."
}

# Function to install Visual Studio Code
install_vscode() {
  echo ""
  echo "  📦 Installing Visual Studio Code..."

  if ! brew list --cask visual-studio-code &>/dev/null; then
    brew install --cask visual-studio-code
    echo "  ✅ Visual Studio Code installed."

    
    # Move Visual Studio Code to the Applications folder if not there already
    if [ -d "/Applications/Visual Studio Code.app" ]; then
      echo "  ✅ Visual Studio Code is already in the Applications folder."
    else
      echo "  📦 Moving Visual Studio Code to the Applications folder..."
      sudo mv "/Applications/Visual Studio Code.app" /Applications/
    fi

    # Link the `code` command to the terminal
    if ! command -v code &> /dev/null; then
      echo "  📦 Linking 'code' command to terminal..."
      sudo ln -s "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code
      echo "  ✅ 'code' command linked to terminal."
    else
      echo "  ✅ 'code' command is already available."
    fi
    echo "  ✅ Visual Studio Code installed, moved to Applications folder, and 'code' command linked!"
  else
    echo "  ✅ Visual Studio Code is already installed, skipping the installation."
  fi
}

#Funcatuin to install Git
install_git() {

  echo ""
  echo "  📦 Installing Git..."

  if ! command -v git &> /dev/null; then 
    brew install git
    echo "  ✅ Git installed."
  else
    echo "  ✅ Git is already installed, skipping."
  fi
}

#Funcatuin to set SSH Keys for GitLab using Token and clone user projects 
install_gitlab_ssh_and_clone() {

  echo ""
  echo "  📦 Setting GitLab SSH keys and Clone repositores ..."
  echo ""
  echo "  ⚠️  IMPORTANT: Make sure you are connected to the SolarEdge VPN!"
  echo "      GitLab access requires VPN connectivity if you're not on-site."
  
  echo ""
  echo "  🔐 To access GitLab APIs, a Personal Access Token (PAT) is required."
  echo "  Please generate one with **api** and **write_repository** scopes from:"
  echo "    👉 https://gitlab.solaredge.com/-/profile/personal_access_tokens"
  echo ""
  read -rp "Enter your GitLab Personal Access Token: " GITLAB_TOKEN

  # Validate GitLab token
  if ! validate_gitlab_token; then
    echo "  ❌ Invalid GitLab token. Exiting setup."
    return 1
  fi
  generate_ssh_key
  upload_ssh_key_to_gitlab
  clone_backend_repos
}

# Function to install Postman via Homebrew and ensure it's in /Applications
install_postman2() {
  echo ""
  echo "  🧪 Checking for Postman installation..."

  if [ -d "/Applications/Postman.app" ]; then
    echo "  ✅ Postman is already installed in /Applications. Skipping installation."
    return 0
  fi

  echo ""
  echo "  📦 Installing Postman via Homebrew..."
  brew install --cask postman

  # Ensure it's moved to /Applications
  POSTMAN_PATH="/Applications/Postman.app"
  if [ ! -d "$POSTMAN_PATH" ]; then
    echo "  🚚 Moving Postman to /Applications..."
    mv /opt/homebrew/Caskroom/postman/*/Postman.app "$POSTMAN_PATH"
  fi

  echo "  ✅ Postman is ready in /Applications."
}

# Generate SSH key pair for GitLab access
generate_ssh_key() {
  echo "🔐 Generating SSH key for GitLab..."

  # Prompt for GitLab username
  read -p "Enter your GitLab username (pattern: <first-name>.<first-initial-of-last-name>): " GITLAB_USER

  # Basic validation: must match pattern like john.d
  if [[ ! "$GITLAB_USER" =~ ^[a-z]+\.{1}[a-z]{1}$ ]]; then
    echo "❌ Invalid username format. Expected pattern: <first-name>.<first-initial-of-last-name>"
    return 1
  fi

  KEY_PATH="$HOME/.ssh/id_gitlab_solaredge"
  SSH_CONFIG="$HOME/.ssh/config"

  # Ensure .ssh directory exists with correct permissions
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # If key exists, delete it
  if [[ -f "$KEY_PATH" || -f "$KEY_PATH.pub" ]]; then
    echo "⚠️ Existing SSH key found at $KEY_PATH. Overwriting..."
    rm -f "$KEY_PATH" "$KEY_PATH.pub"
  fi

  # Generate new SSH key
  ssh-keygen -t ed25519 -C "$GITLAB_USER@solaredge.com" -f "$KEY_PATH" -N ""
  echo "✅ SSH key generated successfully!"

  echo "📎 Public key content:"
  cat "$KEY_PATH.pub"

  echo "🛠️ Configuring SSH for GitLab..."

  # Create SSH config file if it doesn't exist
  if [[ ! -f "$SSH_CONFIG" ]]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
  fi

  # Remove any existing GitLab-related blocks
  sed -i.bak '/Host gitlab.com/,/^[^ ]/d' "$SSH_CONFIG"
  sed -i.bak '/Host gitlab.solaredge.com/,/^[^ ]/d' "$SSH_CONFIG"

  # Append updated config block
  {
    echo ""
    echo "# GitLab.com"
    echo "Host gitlab.com"
    echo "  PreferredAuthentications publickey"
    echo "  IdentityFile ~/.ssh/id_gitlab_solaredge"
    echo ""
    echo "# Private GitLab instance"
    echo "Host gitlab.solaredge.com"
    echo "  PreferredAuthentications publickey"
    echo "  IdentityFile ~/.ssh/id_gitlab_solaredge"
  } >> "$SSH_CONFIG"

  echo "✅ SSH config updated at $SSH_CONFIG"
}

# Upload SSH public key to GitLab
upload_ssh_key_to_gitlab() {
  echo ""
  echo "📤 Uploading SSH public key to GitLab..."

  local KEY_PATH="$HOME/.ssh/id_gitlab_solaredge.pub"

  if [[ ! -f "$KEY_PATH" ]]; then
    echo "❌ SSH public key not found at $KEY_PATH. Generate it first."
    return 1
  fi

  local pub_key
  pub_key=$(< "$KEY_PATH")

  # Use GitLab API to upload the SSH key
  response=$(curl --silent --fail --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --data-urlencode "title=Mac Dev SSH Key" \
    --data-urlencode "key=$pub_key" \
    https://gitlab.solaredge.com/api/v4/user/keys)

  if [ $? -eq 0 ]; then
    echo "✅ SSH key successfully added to GitLab."
  else
    echo "❌ Failed to upload SSH key. It may already exist or token may be invalid."
  fi
}

# Validate GitLab token by making an API request
validate_gitlab_token() {
  echo "  🔍 Validating GitLab token..."
  local response
  response=$(curl -s -o /dev/null -w "%{http_code}" --header "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.solaredge.com/api/v4/user)

  if [ "$response" == "200" ]; then
    echo "  ✅ Token is valid!"
    return 0
  else
    echo "  ❌ Token is invalid. Please recheck scopes or regenerate."
    return 1
  fi
}

# Clone all repositories under backend group 
clone_backend_repos() {
  echo ""
  echo "  📦 Do you want to clone the all backend repositories from GitLab?"
  select opt in "Yes" "No"; do
    case $opt in
      "Yes")
        echo "  🔍 Fetching repositories from GitLab group 'cloud-sw/installer/backend'..."

        # Get the group ID
        group_info=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
          "https://gitlab.solaredge.com/api/v4/groups/cloud-sw%2Finstaller%2Fbackend")

        group_id=$(echo "$group_info" | jq -r '.id')
        echo "  📥 Group ID: $group_id"

        # Ask user for custom clone directory
        DEFAULT_DIR="$HOME/git_projects"
        read -rp "Enter directory to clone repositories into [default: $DEFAULT_DIR]: " CLONE_DIR
        CLONE_DIR="${CLONE_DIR:-$DEFAULT_DIR}"

        # Create target directory if needed
        mkdir -p "$CLONE_DIR"

        # Fetch list of repositories
        repos=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
          "https://gitlab.solaredge.com/api/v4/groups/$group_id/projects?per_page=100" \
          | jq -r '.[].path')

        total=$(echo "$repos" | wc -l)
        echo ""
        echo "  📊 Total repositories in group: $total"
        echo "  📃 Listing all repositories under 'backend':"
        echo "$repos" | sed 's/^/    • /'

        echo ""
        echo "  🔽 Cloning first all repositories into: $CLONE_DIR"

        echo "$repos" | while read -r repo_name; do
          repo_dir="$CLONE_DIR/$repo_name"

          # Check if the directory already exists
          if [ -d "$repo_dir" ]; then
            echo "    ⚠️ Repository '$repo_name' already exists in '$CLONE_DIR'. Skipping..."
          else
            echo "    ⏳ Cloning '$repo_name'..."
            git clone "git@gitlab.solaredge.com:cloud-sw/installer/backend/$repo_name.git" "$repo_dir"
          fi
        done

        echo "  ✅ Done cloning repositories."
        break
        ;;
      "No")
        echo "  ⏩ Skipping repository clone."
        break
        ;;
      *)
        echo "Invalid option. Please select 1 (Yes) or 2 (No)."
        ;;
    esac
  done
}

# Function to uninstall Git
uninstall_git() {
  echo ""
  echo "  🧹 Uninstalling Git..."

  if brew list git &> /dev/null; then
    brew uninstall git
    echo "  ✅ Git uninstalled."
  else
    echo "  ⚠️ Git is not installed via Homebrew, skipping uninstallation."
  fi
}

# FUnction to install docker desktop 
install_docker() {
  echo ""
  echo "  🐳 Installing Docker Desktop for macOS..."

  if ! brew list --cask docker &> /dev/null; then
    brew install --cask docker
    echo "  ✅ Docker Desktop installed."
    echo "  📢 Please launch Docker Desktop manually from Applications for the first time to finish setup."
  else
    echo "  ✅ Docker Desktop is already installed, skipping."
  fi
}

uninstall_docker() {
  echo ""
  echo "  🧹 Uninstalling Docker Desktop for macOS..."

  if brew list --cask docker &> /dev/null; then
    brew uninstall --cask docker
    echo "  ✅ Docker Desktop uninstalled."
  else
    echo "  ⚠️ Docker Desktop is not installed via Homebrew, skipping."
  fi

  echo "  🧼 Removing Docker-related files from ~/Library and /Library..."
  rm -rf ~/Library/Containers/com.docker.docker
  rm -rf ~/.docker
  sudo rm -rf /Library/PrivilegedHelperTools/com.docker.vmnetd
  sudo rm -rf /Library/LaunchDaemons/com.docker.vmnetd.plist
  echo "  ✅ Docker config and system files cleaned."
}

install_docker_aliases() {
  echo ""
  echo "  🧩 Setting up Docker and Docker Compose aliases..."

  SHELL_CONFIG=""
  if [[ $SHELL == *"zsh" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
  elif [[ $SHELL == *"bash" ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
  else
    echo "  ⚠️ Unsupported shell. Please add aliases manually."
    return
  fi

  {
    echo ""
    echo "# ===== Docker Aliases ====="
    echo "alias d='docker'"
    echo "alias dps='docker ps'"
    echo "alias dpsa='docker ps -a'"
    echo "alias di='docker images'"
    echo "alias dcu='docker compose up'"
    echo "alias dcuo='docker compose up --build --remove-orphans'"
    echo "alias dcd='docker compose down'"
    echo "alias dcb='docker compose build'"
    echo "alias dcl='docker compose logs'"
    echo "alias dclf='docker compose logs -f'"
    echo "alias dexec='docker exec -it'"
    echo "alias dstats='docker stats'"
    echo "alias drm='docker rm \$(docker ps -aq)'"
    echo "alias drmi='docker rmi \$(docker images -q)'"
    echo "alias dclean='docker system prune -af --volumes'"
    echo "alias dnet='docker network ls'"
    echo "alias dvol='docker volume ls'"
    echo "alias dstop='docker stop \$(docker ps -q)'"
    echo "alias dstart='docker start \$(docker ps -aq)'"
    echo "alias dkill='docker kill \$(docker ps -q)'"
    echo "alias dlogs='docker logs -f'"
    echo "alias dcontext='docker context ls'"
    echo "# ==========================="
  } >> "$SHELL_CONFIG"

  echo "  ✅ Docker aliases added to $SHELL_CONFIG"
  echo "  📢 Run 'source $SHELL_CONFIG' or restart your terminal to activate them."
}

install_sdkman_and_java() {
  echo ""
  echo "  ☕ Installing SDKMAN and Temurin Java 17–24..."

  # Step 1: Install SDKMAN if missing
  if [ -d "$HOME/.sdkman" ]; then
    echo "  ✅ SDKMAN already installed."
  else
    echo "  Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    echo "  ✅ SDKMAN installed."
  fi

  # Step 2: Source SDKMAN into current shell
  if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
  else
    echo "❌ Could not initialize SDKMAN."
    return 1
  fi

  # Step 3: Add SDKMAN init to .zshrc if not already there
  if ! grep -q 'sdkman-init.sh' "$HOME/.zshrc"; then
    echo "  Adding SDKMAN to .zshrc..."
    {
      echo ""
      echo "# SDKMAN initialization"
      echo "export SDKMAN_DIR=\"$HOME/.sdkman\""
      echo "source \"\$SDKMAN_DIR/bin/sdkman-init.sh\""
    } >> "$HOME/.zshrc"
  fi

  echo ""
  echo "  🔍 Fetching available Temurin versions..."
  
  # Step 4: Get the list of Temurin versions from sdk list java
  available_versions=$(sdk list java | grep -E '\|\s*tem\s*\|' | awk '{print $NF}' | grep '^.*-tem$')

  echo ""
  echo "  📦 Installing Temurin versions 17–24..."
  for version in $available_versions; do
    major=$(echo "$version" | grep -oE '^[0-9]+')
    if [ "$major" -ge 17 ] && [ "$major" -le 24 ]; then
      echo "    ➤ Installing $version"
      sdk install java "$version"
    fi
  done

  # Step 5: Set Java 17 as default if available
  echo ""
  echo "  🎯 Setting Temurin 17 as default (if installed)..."
  default_version=$(sdk list java | grep 'tem' | grep '^.*17.*-tem' | awk '{print $NF}' | head -n 1)

  if [[ -n "$default_version" ]]; then
    sdk default java "$default_version"
    echo "  ✅ Java $default_version is now the default version."
  else
    echo "  ⚠️ Could not find a Temurin 17 version to set as default."
  fi

  # Step 6: Add Java switching aliases
  {
    echo ""
    echo "# ===== Java SDK Switch Aliases ====="
    echo "alias j17='sdk use java 17.*-tem'"
    echo "alias j21='sdk use java 21.*-tem'"
    echo "alias j22='sdk use java 22.*-tem'"
    echo "# ==================================="
  } >> "$SHELL_CONFIG"
  echo "  ✅ Java version aliases added to $SHELL_CONFIG"
}

install_iterm2() {
  echo ""
  echo "  🖥️ Installing iTerm2..."

  if ! brew list --cask iterm2 &> /dev/null; then
    brew install --cask iterm2
    echo "  ✅ iTerm2 installed."
  else
    echo "  ✅ iTerm2 already installed, skipping."
  fi

  echo ""
  echo "  📁 Ensuring iTerm2 is in the Applications folder..."
  if [ -d "/Applications/iTerm.app" ]; then
    echo "  ✅ iTerm2 is already in the Applications folder."
  else
    echo "  📦 Moving iTerm2 to the Applications folder..."
    sudo mv "$(find /usr/local/Caskroom/iterm2 -name 'iTerm.app' -type d | head -n 1)" /Applications/ 2>/dev/null || \
    sudo cp -R /usr/local/Caskroom/iterm2/*/*.app /Applications/
    echo "  ✅ iTerm2 moved to Applications."
  fi
}

uninstall_iterm2() {
  echo ""
  echo "  🧹 Uninstalling iTerm2..."

  if brew list --cask iterm2 &> /dev/null; then
    brew uninstall --cask iterm2
    echo "  ✅ iTerm2 uninstalled via Homebrew."
  else
    echo "  ⚠️ iTerm2 is not installed via Homebrew, skipping brew uninstall."
  fi

  echo ""
  echo "  🧼 Removing iTerm2 from Applications folder if it exists..."
  if [ -d "/Applications/iTerm.app" ]; then
    sudo rm -rf /Applications/iTerm.app
    echo "  ✅ iTerm2 removed from Applications folder."
  else
    echo "  ⚠️ iTerm2 not found in Applications folder."
  fi
}

uninstall_sdkman_and_java() {
  echo ""
  echo "  🧹 Uninstalling SDKMAN and all Java versions..."

  # Remove SDKMAN directory
  if [ -d "$HOME/.sdkman" ]; then
    rm -rf "$HOME/.sdkman"
    echo "  ✅ SDKMAN directory removed."
  else
    echo "  ⚠️ SDKMAN directory not found. Skipping removal."
  fi

  # Clean up shell configuration
  SHELL_CONFIG=""
  if [[ $SHELL == *"zsh" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
  elif [[ $SHELL == *"bash" ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
  fi

  if [[ -n "$SHELL_CONFIG" && -f "$SHELL_CONFIG" ]]; then
    sed -i '' '/sdkman/d' "$SHELL_CONFIG"
    echo "  ✅ Removed SDKMAN initialization from $SHELL_CONFIG"
  fi

  echo "  📢 Please run 'source $SHELL_CONFIG' or restart your terminal to apply the cleanup."
}

uninstall_docker_aliases() {
  echo ""
  echo "  🧽 Removing Docker aliases from your shell config..."

  SHELL_CONFIG=""
  if [[ $SHELL == *"zsh" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
  elif [[ $SHELL == *"bash" ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
  else
    echo "  ⚠️ Unsupported shell. Please remove aliases manually."
    return
  fi

  if grep -q "# ===== Docker Aliases =====" "$SHELL_CONFIG"; then
    # Remove lines between the alias block markers
    sed -i '' '/# ===== Docker Aliases =====/,/# ===========================/d' "$SHELL_CONFIG"
    echo "  ✅ Docker aliases removed from $SHELL_CONFIG"
    echo "  📢 Run 'source $SHELL_CONFIG' or restart your terminal to apply changes."
  else
    echo "  ℹ️ No Docker alias block found in $SHELL_CONFIG. Nothing to remove."
  fi
}

# Function to uninstall IntelliJ IDEA Ultimate
uninstall_intellij() {
  echo ""
  echo "  🧹 Uninstalling IntelliJ IDEA Ultimate..."
  brew uninstall --cask intellij-idea
  echo "  ✅ IntelliJ IDEA Ultimate uninstalled."

  echo ""
  echo "  Removing IntelliJ IDEA from Applications folder..."
  sudo rm -rf /Applications/IntelliJ\ IDEA.app
  echo "  ✅ IntelliJ IDEA removed from Applications folder."
}

# Function to install IntelliJ IDEA Ultimate
install_intellij() {
  echo ""
  echo "  📦 Installing IntelliJ IDEA Ultimate..."

  if ! brew list --cask intellij-idea &>/dev/null; then
    brew install --cask intellij-idea
    echo "  ✅ IntelliJ IDEA Ultimate installed."

    echo ""
    # Move IntelliJ IDEA to the Applications folder if not there already
    if [ -d "/Applications/IntelliJ IDEA.app" ]; then
      echo "  ✅ IntelliJ IDEA is already in the Applications folder."
    else
      echo "  📦 Moving IntelliJ IDEA to the Applications folder..."
      sudo mv "/Applications/IntelliJ IDEA.app" /Applications/
    fi

    echo ""
    echo "  ✅ IntelliJ IDEA Ultimate installed and moved to Applications folder!"
  else
    echo "  ✅ IntelliJ IDEA Ultimate is already installed, skipping the installation."
  fi
}

# Ask user for installation or uninstallation
echo "What would you like to do?"
select action in "Install" "Uninstall" "Abort"; do
  case $action in
    "Install")
      # Step 0: Update Homebrew
      ask_choice "Step 0: Update Homebrew" "Install" && update_homebrew
      # Step 1: Install Visual Studio Code
      ask_choice "Step 1: Install Visual Studio Code" "Install" && install_vscode
      # Step 2: Install IntelliJ IDEA Ultimate
      ask_choice "Step 2: Install IntelliJ IDEA Ultimate" "Install" && install_intellij
      # Step 3: Install Git
      ask_choice "Step 3: Install Git" "Install" && install_git 
      # Step 4: Generate GitLab SSH keys & Clone Projects
      ask_choice "Step 4:  Generate GitLab SSH keys & Clone Projects" "Install" && install_gitlab_ssh_and_clone 
      # Step 5: Install docker
      ask_choice "Step 5: Install Docker Desktop" "Install" && install_docker 
      # Step 6: Install Docker & Docker compose Aliases
      ask_choice "Step 6: Install Docker & Docker compose Aliases" "Install" && install_docker_aliases 
      # Step 7: Install SDKMan & Java Termurin version {17..24}
      ask_choice "Step 7: SDKMan & Java Termurin version {17..24}" "Install" && install_sdkman_and_java 
      # Step 8: Install iTerms2
      ask_choice "Step 8: install iTerm2" "Install" && install_iterm2 
      # Step 9: Install Postman 2 
      ask_choice "Step 9: install Postman 2" "Install" && install_postman2 
      break
      ;;
    "Uninstall")
      # Step 1: Uninstall Visual Studio Code
      ask_choice "Step 1: Uninstall Visual Studio Code" "Uninstall" && uninstall_vscode
      # Step 2: Uninstall IntelliJ IDEA Ultimate
      ask_choice "Step 2: Uninstall IntelliJ IDEA Ultimate" "Uninstall" && uninstall_intellij
      # Step 3: Uninstall Git
      ask_choice "Step 3: Uninstall Git" "Uninstall" && uninstall_git
      # Step 4: Uninstall docker
      ask_choice "Step 4: Uninstall Docker Desktop" "Uninstall" && uninstall_docker
      # Step 5: Uninstall Docker & Docker compose Aliases
      ask_choice "Step 5: Uninstall Docker & Docker compose Aliases" "Uninstall" && uninstall_docker_aliases 
      # Step 6: Uninstall SDKMan & Java Termurin version {17..24}
      ask_choice "Step 6: Uninstall SDKMan & Java Termurin version {17..24}" "Install" && uninstall_sdkman_and_java 
      # Step 7: Uninstall iTerms2
      ask_choice "Step 7: install iTerm2" "Uninstall" && uninstall_iterm2 
      break
      ;;
    "Abort")
      echo "❌ Aborting the process."
      exit 1
      ;;
    *)
      echo "Invalid option. Please select 1 (Install), 2 (Uninstall), or 3 (Abort)."
      ;;
  esac
done

echo ""
echo "🎉 Operation completed!"
