#
# Homebrew
#

if [[ "$OSTYPE" == darwin* ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

#
# Paths
#

export PATH="$HOME/.claude/local:$HOME/bin:$HOME/.local/bin:$HOME/.deno/bin:$HOME/.go/bin:$HOME/.cargo/bin:$PATH"

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
# Others
#

export CARGO_INCREMENTAL=true

#
# Open telemetry
#

export OTEL_DENO=true # for deno

export CLAUDE_CODE_ENABLE_TELEMETRY=1 # for claude code
export OTEL_LOG_USER_PROMPTS=1        # show user prompts

export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
# export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

export OTEL_METRIC_EXPORT_INTERVAL=10000 # 10sec(default: 60000ms)
export OTEL_LOGS_EXPORT_INTERVAL=5000    # 5sec(default: 5000ms)

#
# Local configuration file. e.g ACCESS_TOKEN, API_KEY, etc.
#

if [[ -f "$HOME/.profile.local" ]]; then
  source "$HOME/.profile.local"
fi
