# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Formatting
- **Format Lua files**: `stylua <file>` or `stylua .` for all files
  - Configuration in `stylua.toml`: 2 spaces, 120 column width

### Git Operations
- **Open Neogit**: `<Space>gg` in Neovim
- **Git commit**: `<Space>gcc` in Neovim (opens scratch buffer)
- **AI-powered commit**: `<Space>gca` in Neovim (uses CopilotChat to generate conventional commit messages)

### Development Workflow
- **Reload configuration**: `:source %` or `<Space>r` in Neovim
- **Install/update plugins**: `:Lazy sync` in Neovim
- **Check plugin status**: `:Lazy` in Neovim

## Architecture

This is a **LazyVim-based Neovim configuration** that extends the base distribution with custom plugins and settings.

### Structure
- `init.lua`: Entry point that loads LazyVim
- `lua/config/`: Core configuration modules
  - `lazy.lua`: Plugin manager setup and LazyVim bootstrap
  - `keymaps.lua`: Custom keybindings (Space-prefixed commands, Emacs-style insert mode)
  - `autocmds.lua`: Auto-commands (Deno LSP auto-configuration)
  - `options.lua`: Vim options (UTF-8, system clipboard)
- `lua/plugins/`: Plugin specifications that extend/override LazyVim defaults
  - `colorscheme.lua`: Solarized theme configuration
  - `neogit.lua`: Git integration setup

### Key Features
1. **AI Integration**: Copilot and CopilotChat for code completion and commit message generation
2. **Git Workflow**: Neogit integration with custom commit helpers, including AI-powered conventional commits
3. **Smart Keybindings**: Space-based commands inspired by Vimperator, Emacs-style navigation in insert mode
4. **Language Support**: Auto-configures Deno LSP when `deno.json` is detected
5. **Modern Tools**: Uses ripgrep, fd, fzf for fast searching and navigation

### Plugin Management
LazyVim uses lazy.nvim for plugin management. Plugins are:
- Specified in `lua/plugins/` directory
- Can override LazyVim defaults by returning specs with the same plugin name
- Locked to specific versions in `lazy-lock.json`

### Extending Configuration
- Add new plugins: Create files in `lua/plugins/`
- Override LazyVim plugins: Return a spec with the same plugin name
- Add keymaps: Extend `lua/config/keymaps.lua`
- Add autocmds: Extend `lua/config/autocmds.lua`