#!/usr/bin/env bash -ex

install_packages() {
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    export HOMEBREW_NO_AUTO_UPDATE=1

    # Install CLI packages
    brew bundle install --verbose --file=Brewfile

    # Install GUI packages
    if [[ "$OSTYPE" == darwin* ]]; then
        brew bundle install --verbose --file=Brewfile.darwin
    else
        cat Flatpakfile | xargs flatpak install flathub
    fi
}

create_hardlinks() {
    local src="$1"
    local dest="$2"
    local exclude="^(.git|install.sh|README.md|Brewfile|Brewfile.darwin|Flatpakfile)$"

    # Iterate through items in the source directory
    shopt -s dotglob
    for item in "$src"/*; do
        local name="$(basename "$item")"
        if [[ "$name" =~ $exclude ]]; then
            continue
        fi
        if [ -d "$item" ]; then
            # If item is a directory, create the directory in the target and recurse
            local subdir="$dest/$(basename "$item")"
            mkdir -p "$subdir"
            create_hardlinks "$item" "$subdir"
        elif [ -f "$item" ]; then
            # If item is a file, create a hard link
            ln -f "$item" "$dest"
        fi
    done
    shopt -u dotglob
}

if [ -z "$HOME" ]; then
    echo "Error: HOME environment variable is not set."
    exit 1
fi

if [ -z "$OSTYPE" ]; then
    echo "Error: OSTYPE environment variable is not set."
    exit 1
fi

if [[ "$OSTYPE" != darwin* ]]; then
    if ! command -v flatpak &> /dev/null; then
        echo "Error: flatpak command is missing."
        exit 1
    fi
fi

if [ ! -d "$HOME/dotfiles" ]; then
  git clone --depth 1 https://github.com/hirochachacha/dotfiles.git "$HOME/dotfiles"
fi

install_packages

create_hardlinks "$HOME/dotfiles" "$HOME"

# Install fonts
if [[ "$OSTYPE" == darwin* ]]; then
  create_hardlinks "$HOME/.local/share/fonts" "$HOME/Library/Fonts"
else
  fc-cache
fi

if [ ! -d "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim" ]; then
  git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
fi
