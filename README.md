# macOS Developer Setup Script

This repository contains an interactive macOS setup script designed to configure a full development environment. It provides an easy way to install essential tools, configure your workspace, and clone your GitLab repositories.

## 🛠️ Features

- Choose which steps to run or skip
- Abort the process at any step
- Configure development tools, shell environment, and Java versions
- Ideal for clean setups, onboarding, or rapid recovery

---

## 🧑‍💻 Pre Requirements

- macOS (tested on Apple Silicon)
- Internet connection with VPN
- **You must run `bootstrap.sh` before running `dev-setup.sh`**


### 🔧 Bootstrap Prerequisite

Before running the `dev-setup.sh` script, make sure you run the `bootstrap.sh` script to prepare your environment by install Homebrew and set default shell to Zsh.
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```
- **Link**: [Zsh](https://ohmyz.sh/)
- **Link**: [Homebrew](https://brew.sh/)
---

## 🚀 Getting Started

Download script to your local env

```bash
chmod +x dev-setup.sh
./dev-setup.sh
```
---

## 📦 Installation Steps

Each step is presented with an interactive prompt:
- **Install** — proceeds with the step.
- **Skip** — moves to the next step.
- **Abort** — exits the script.

This ensures a flexible and personalized setup experience.

---

### **Step 0: Update Homebrew**
- **Description**: Updates Homebrew, the macOS package manager.
- **Purpose**: Ensures access to the latest versions of software.
- **Link**: [https://brew.sh](https://brew.sh)

---

### **Step 1: Install Visual Studio Code**
- **Description**: Installs VS Code via Homebrew Cask.
- **Purpose**: Used as a versatile editor for general development, scripting, and quick editing tasks. Ideal for lightweight operations, terminal integration, and managing project files outside full-fledged IDEs.
- **Link**: [https://code.visualstudio.com](https://code.visualstudio.com)

---

### **Step 2: Install IntelliJ IDEA Ultimate**
- **Description**: Installs IntelliJ IDEA Ultimate via Homebrew Cask, and ensures it's placed in the /Applications folder.
- **Purpose**: Used as the primary IDE for complex software development, particularly for Java projects. Offers deep code insight, debugging, refactoring, Git integration, and full Spring Boot support.
- **Link**: [https://www.jetbrains.com/idea](https://www.jetbrains.com/idea)

---

### **Step 3: Install Git**
- **Description**: Installs Git, a distributed version control system.
- **Purpose**: Enables version control and collaboration.
- **Link**: [https://git-scm.com](https://git-scm.com)

---

### Step 4: Generate GitLab SSH Keys & Clone Installer Backend Projects
- **Description**: Automates the creation of a GitLab-compatible SSH key, uploads it via GitLab's API using your Personal Access Token (PAT), configures your SSH client for seamless access, and offers to clone all repositories under SolarEdge’s `cloud-sw/installer/backend` group.
- **Purpose**: This step ensures secure, password-less Git access over SSH, improves Git workflow automation, and instantly sets up your local development environment with all backend repositories.
- **Special Notes**:
  - 🔐 You’ll need to provide a [GitLab Personal Access Token](https://gitlab.solaredge.com/-/profile/personal_access_tokens) with `api` and `write_repository` scopes.
  - 🌐 Ensure you are connected to the **SolarEdge VPN** when running this step, as GitLab access requires VPN connectivity if you're not on-site.
  - 📁 Repositories are cloned to `~/git_projects` by default, but you can specify a different directory during the process.
- **Link**: [SolarEdge GitLab](https://gitlab.solaredge.com)
---

### Step 5: Install Docker Desktop
- **Description**: Installs Docker Desktop for macOS via Homebrew.
- **Purpose**: Docker is essential for creating, deploying, and running applications in containers. This step ensures you have Docker Desktop installed and ready to use for your development workflows.
- **Special Notes**:
  - 🐳 Docker Desktop provides a GUI to manage containers, images, and more, in addition to the command-line interface.
  - 📢 After installation, you need to launch Docker Desktop manually from the **Applications** folder to complete the initial setup process.

- **Link**: [Docker Desktop](https://www.docker.com/products/docker-desktop)
---

### Step 6: Install Docker & Docker Compose Aliases
- **Description**: Installs Docker and Docker Compose aliases to simplify Docker commands and enhance your development workflow.
- **Purpose**: These aliases provide shortcuts for frequently used Docker and Docker Compose commands, making it faster and easier to manage containers, images, and volumes.
- **Special Notes**:
  - 🧩 Aliases are added to your shell configuration file (e.g., `.zshrc` for Zsh or `.bashrc` for Bash).
  - 📢 After the aliases are installed, you need to run `source ~/.zshrc` (or `source ~/.bashrc` for Bash users) or restart your terminal to activate them.
  - 🚀 These aliases will help you speed up your Docker operations by reducing the amount of typing required.

- **Aliases Installed**:
  ```bash
  # ===== Docker Aliases =====
  alias d='docker'
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias di='docker images'
  alias dcu='docker compose up'
  alias dcuo='docker compose up --build --remove-orphans'
  alias dcd='docker compose down'
  alias dcb='docker compose build'
  alias dcl='docker compose logs'
  alias dclf='docker compose logs -f'
  alias dexec='docker exec -it'
  alias dstats='docker stats'
  alias drm='docker rm \$(docker ps -aq)'
  alias drmi='docker rmi \$(docker images -q)'
  alias dclean='docker system prune -af --volumes'
  alias dnet='docker network ls'
  alias dvol='docker volume ls'
  alias dstop='docker stop \$(docker ps -q)'
  alias dstart='docker start \$(docker ps -aq)'
  alias dkill='docker kill \$(docker ps -q)'
  alias dlogs='docker logs -f'
  alias dcontext='docker context ls'
  # ===========================
---

### Step 7: Install SDKMAN & Java Temurin Versions (17–24)
- **Description**: Installs SDKMAN and Java Temurin versions 17 through 24, allowing you to manage different versions of Java for development.
- **Purpose**: SDKMAN is a tool that facilitates the installation and management of parallel versions of multiple Software Development Kits, including Java. Installing Temurin Java 17–24 ensures compatibility with the required Java versions for your development environment.

- **Aliases Installed**:
  ```bash
  # ===== Java SDK Switch Aliases =====
  alias j17='sdk use java 17.*-tem'
  alias j21='sdk use java 21.*-tem'
  alias j22='sdk use java 22.*-tem'
  # ===================================
---

### Step 8: Install iTerm2
- **Description**: Installs iTerm2 via Homebrew and ensures it is placed in the `/Applications` folder.
- **Purpose**: iTerm2 is a powerful terminal emulator for macOS that offers better features, performance, and customization than the default Terminal app.
- **Link**: [iTerm2](https://iterm2.com/)

---

### Step 9: Install Postman
- **Description**: Installs Postman using Homebrew and ensures it's placed in the `/Applications` folder.
- **Purpose**: Postman is a popular tool for testing, documenting, and automating RESTful 
- **Link**: [Postman](https://www.postman.com/downloads/)

---

