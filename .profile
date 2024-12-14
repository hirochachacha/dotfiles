#
# Browser
#

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER='open'
fi

#
# Editors
#

export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'

#
# Language
#

export LANG='en_US.UTF-8'

#
# Less
#

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

#
# Paths
#

if [[ "$OSTYPE" == darwin* ]]; then
  export PATH="$HOME/bin:$HOME/.deno/bin:$HOME/.go/bin:$HOME/.cargo/bin:/opt/homebrew/bin:$PATH"
else
  export PATH="$HOME/bin:$HOME/.deno/bin:$HOME/.go/bin:$HOME/.cargo/bin:$PATH"
fi

#
# Others
#

export CARGO_INCREMENTAL=true

#
# Local configuration file. e.g ACCESS_TOKEN, API_KEY, etc.
#

if [[ -f "$HOME/.profile.local" ]]; then
  source "$HOME/.profile.local"
fi
