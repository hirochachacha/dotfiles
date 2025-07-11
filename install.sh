#!/usr/bin/env bash

set -ex

DOTFILES_DIR="$HOME/dotfiles"

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    export PATH="/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

    if ! command -v brew &>/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    eval "$(brew shellenv)"
  fi
}

install_packages() {
  export HOMEBREW_NO_AUTO_UPDATE=1

  # Install CLI packages
  brew bundle install --verbose --file="$DOTFILES_DIR/Brewfile"

  # Install GUI packages
  if [[ "$OSTYPE" == darwin* ]]; then
    brew install mas
    brew bundle install --verbose --file="$DOTFILES_DIR/Brewfile.darwin"
  else
    if ! command -v flatpak &>/dev/null; then
      echo "Warning: flatpak command is missing. skipping GUI package installation."
    else
      cat "$DOTFILES_DIR/Flatpakfile" | xargs flatpak -y install flathub
    fi
  fi
}

create_hardlinks() {
  local src="$1"
  local dest="$2"

  # Iterate through items in the source directory
  shopt -s dotglob
  for item in "$src"/*; do
    local name="$(basename "$item")"
    if [ -d "$item" ]; then
      # If item is a directory, create the directory in the target and recurse
      local subdir="$dest/$name"
      mkdir -p "$subdir"
      create_hardlinks "$item" "$subdir"
    elif [ -f "$item" ]; then
      # If item is a file, create a hard link
      ln -f "$item" "$dest"
    fi
  done
  shopt -u dotglob
}

main() {
  if [ -z "$HOME" ]; then
    echo "Error: HOME environment variable is not set."
    exit 1
  fi

  if [ -z "$OSTYPE" ]; then
    echo "Error: OSTYPE environment variable is not set."
    exit 1
  fi

  if [ ! -d "$DOTFILES_DIR" ]; then
    git clone --depth 1 https://github.com/hirochachacha/dotfiles.git "$DOTFILES_DIR"
  fi

  install_homebrew

  install_packages

  create_hardlinks "$DOTFILES_DIR/HOME" "$HOME"

  # Install fonts
  if [[ "$OSTYPE" == darwin* ]]; then
    create_hardlinks "$HOME/.local/share/fonts" "$HOME/Library/Fonts"
  else
    fc-cache
  fi
}

main "$@"
