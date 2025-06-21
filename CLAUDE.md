# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Installation and Setup
- **Full installation**: `./install.sh` (installs Homebrew, packages, and creates hardlinks)
- **Quick install from remote**: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hirochachacha/dotfiles/HEAD/install.sh)"`
- **Package management**: 
  - `brew bundle install --file=Brewfile` (CLI tools)
  - `brew bundle install --file=Brewfile.darwin` (macOS GUI apps)
  - `cat Flatpakfile | xargs flatpak -y install flathub` (Linux GUI apps)

### Development Workflow
- **Navigate to language package directories**:
  - `gemcd <gem_name>` - Ruby gems
  - `pycd <package_name>` - Python packages  
  - `denocd <module_name>` - Deno modules
  - `gocd <package_name>` - Go packages
- **Shell navigation**: `j <pattern>` or `cd <pattern>` (uses zoxide for smart directory jumping)
- **File operations**: `cat` (uses bat), `ag` (uses ripgrep), `vi` (uses nvim)
- **Directory listing**: Press Enter on empty command line (shows eza output with icons and git status)

### Font Management
- **Refresh font cache** (Linux): `fc-cache`
- **Font installation**: Fonts are automatically hardlinked from `~/.local/share/fonts/` to system font directories

## Architecture

This is a **cross-platform dotfiles repository** that supports both macOS and Linux environments through Homebrew package management and conditional OS-specific configurations.

### Core Components

#### Installation System (`install.sh`)
- **Homebrew Management**: Installs and configures Homebrew for both macOS (`/opt/homebrew`) and Linux (`/home/linuxbrew/.linuxbrew`)
- **Package Installation**: Uses Brewfile for CLI tools, platform-specific files for GUI applications
- **Configuration Deployment**: Creates hardlinks from `HOME/` directory to `$HOME` for live configuration updates
- **Font Management**: Handles font installation with platform-specific paths

#### Shell Environment (`.profile`, `.zshrc`)
- **Universal Profile**: `.profile` sets up PATH, environment variables, and tool configurations
- **Zsh Enhancements**: Custom functions for development workflow, history management, and modern tool integration
- **Tool Integration**: Starship prompt, zoxide navigation, fzf integration, modern CLI tool aliases

#### Configuration Structure (`HOME/`)
```
HOME/
├── .config/
│   ├── nvim/           # LazyVim-based Neovim configuration
│   ├── karabiner/      # macOS keyboard customization
│   ├── zed/           # Zed editor settings
│   └── starship.toml   # Prompt configuration
├── .local/share/fonts/ # Custom font files
├── .raycast/scripts/   # macOS Raycast automation
└── Shell profiles (.profile, .zshrc, .bash_profile, .zprofile)
```

### Key Design Principles

1. **Cross-Platform Compatibility**: Uses Homebrew as universal package manager, conditional OS detection
2. **Live Configuration**: Hardlinks enable real-time configuration updates without reinstallation
3. **Developer Workflow**: Language-specific navigation functions, modern CLI tool integration
4. **Keyboard-Driven**: Emphasis on terminal workflows, keyboard shortcuts, and efficiency tools
5. **Modular Package Management**: Separate Brewfiles for different application categories and platforms

### Platform-Specific Features

#### macOS Integration
- **GUI Applications**: Installed via Homebrew Cask and Mac App Store
- **Keyboard Customization**: Karabiner-Elements for Emacs-style keybindings
- **Application Automation**: Raycast scripts for window management and app toggling
- **System Integration**: Native browser opening, proper font installation paths

#### Linux Integration
- **GUI Applications**: Managed through Flatpak with application ID-based installation
- **Font Management**: Uses fontconfig (`fc-cache`) for font registration
- **Alternative Tools**: Maintains feature parity through equivalent Linux tools

### Development Environment
- **Primary Editor**: Neovim with LazyVim distribution (see `HOME/.config/nvim/CLAUDE.md` for details)
- **Terminal**: WezTerm with custom Lua configuration
- **Git Workflow**: Tig for interactive git operations, integrated with Neovim
- **Language Support**: Pre-configured environments for Go, Rust, Deno, Python, Ruby, Node.js

### Extending the Configuration
- **Add new packages**: Edit appropriate Brewfile or Flatpakfile
- **Add shell functions**: Extend `.zshrc` with new utility functions  
- **Add GUI applications**: Update `Brewfile.darwin` (macOS) or `Flatpakfile` (Linux)
- **Customize shell**: Create `.profile.local` or `.zshrc.local` for user-specific additions
- **Update configurations**: Edit files in `HOME/` directory (changes apply immediately via hardlinks)