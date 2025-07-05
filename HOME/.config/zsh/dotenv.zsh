#!/usr/bin/env zsh

# dotenv - A lightweight .env file loader for zsh
# This loads .env files when entering directories and unloads them when leaving

# Configuration directory for approved .env hashes
DOTENV_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/dotenv"
DOTENV_ALLOWED="$DOTENV_CONFIG/allowed"

# Current loaded env file path
typeset -g DOTENV_CURRENT=""
typeset -gA DOTENV_PREVIOUS_ENV

# Initialize configuration directory
[[ ! -d "$DOTENV_CONFIG" ]] && mkdir -p "$DOTENV_CONFIG"
[[ ! -f "$DOTENV_ALLOWED" ]] && touch "$DOTENV_ALLOWED"

# Calculate SHA256 hash of a file
_dotenv_hash() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        echo "ERROR: No SHA256 tool found" >&2
        return 1
    fi
}

# Check if an .env file is approved
_dotenv_is_allowed() {
    local env_path="$1"
    local env_hash="$(_dotenv_hash "$env_path")"
    grep -q "^${env_path}:${env_hash}$" "$DOTENV_ALLOWED"
}

# Approve an .env file
_dotenv_allow() {
    local env_path="$1"
    local env_hash="$(_dotenv_hash "$env_path")"
    
    # Remove old entries for this path
    grep -v "^${env_path}:" "$DOTENV_ALLOWED" > "${DOTENV_ALLOWED}.tmp" || true
    mv "${DOTENV_ALLOWED}.tmp" "$DOTENV_ALLOWED"
    
    # Add new entry
    echo "${env_path}:${env_hash}" >> "$DOTENV_ALLOWED"
    echo "dotenv: allowed $env_path"
}

# Save current environment variables
_dotenv_save_env() {
    DOTENV_PREVIOUS_ENV=()
    local var
    while IFS= read -r var; do
        DOTENV_PREVIOUS_ENV[$var]="${(P)var}"
    done < <(env | cut -d= -f1)
}

# Restore previous environment, removing new variables
_dotenv_restore_env() {
    local var
    # First pass: collect current environment variables
    local -a current_vars
    while IFS= read -r var; do
        current_vars+=("$var")
    done < <(env | cut -d= -f1)
    
    # Unset variables that weren't in the previous environment
    for var in $current_vars; do
        if [[ ! -v DOTENV_PREVIOUS_ENV[$var] ]]; then
            unset "$var"
        fi
    done
    
    # Restore previous values
    for var in ${(k)DOTENV_PREVIOUS_ENV}; do
        export "$var"="${DOTENV_PREVIOUS_ENV[$var]}"
    done
}

# Parse .env file format (KEY=VALUE, ignoring comments and empty lines)
_dotenv_parse_env() {
    local env_path="$1"
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Parse KEY=VALUE format
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            local key="${match[1]}"
            local value="${match[2]}"
            
            # Remove surrounding quotes if present
            if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${match[1]}"
            fi
            
            export "$key"="$value"
        fi
    done < "$env_path"
}

# Load an .env file
_dotenv_load() {
    local env_path="$1"
    
    if [[ ! -f "$env_path" ]]; then
        return 1
    fi
    
    if ! _dotenv_is_allowed "$env_path"; then
        echo "dotenv: error $env_path is blocked. Run: dotenv allow"
        return 1
    fi
    
    # Save current environment before loading
    _dotenv_save_env
    
    # Parse and load the .env file
    _dotenv_parse_env "$env_path"
    
    DOTENV_CURRENT="$env_path"
    echo "dotenv: loading $env_path"
}

# Unload current environment
_dotenv_unload() {
    if [[ -n "$DOTENV_CURRENT" ]]; then
        _dotenv_restore_env
        echo "dotenv: unloading"
        DOTENV_CURRENT=""
    fi
}

# Track last directory to detect changes
typeset -g DOTENV_LAST_PWD=""

# Hook function to be called on directory change
_dotenv_check() {
    # Save the current PWD
    local saved_pwd="$PWD"
    
    # Get the actual current directory
    local current_dir="$(pwd)"
    
    # Update PWD to match actual directory
    PWD="$current_dir"
    
    # Check if we've actually changed directories
    if [[ "$current_dir" == "$DOTENV_LAST_PWD" ]]; then
        PWD="$saved_pwd"
        return
    fi
    DOTENV_LAST_PWD="$current_dir"
    
    local env_path="$current_dir/.env"
    
    # If we're in the same directory as the currently loaded .env, do nothing
    if [[ -n "$DOTENV_CURRENT" ]] && [[ "$DOTENV_CURRENT" == "$env_path" ]]; then
        PWD="$saved_pwd"
        return
    fi
    
    # If we've moved away from a directory with a loaded .env, unload it
    if [[ -n "$DOTENV_CURRENT" ]] && [[ "$DOTENV_CURRENT" != "$env_path" ]]; then
        _dotenv_unload
    fi
    
    # If current directory has an .env, try to load it
    if [[ -f "$env_path" ]]; then
        _dotenv_load "$env_path"
    fi
    
    # Restore PWD to the actual current directory
    PWD="$current_dir"
}

# User-facing commands
dotenv() {
    case "$1" in
        allow)
            local env_path="${2:-$PWD/.env}"
            [[ ! -f "$env_path" ]] && echo "dotenv: no .env file found" && return 1
            _dotenv_allow "$(realpath "$env_path")"
            _dotenv_check  # Reload if in current directory
            ;;
        deny)
            local env_path="${2:-$PWD/.env}"
            env_path="$(realpath "$env_path")"
            grep -v "^${env_path}:" "$DOTENV_ALLOWED" > "${DOTENV_ALLOWED}.tmp" || true
            mv "${DOTENV_ALLOWED}.tmp" "$DOTENV_ALLOWED"
            echo "dotenv: denied $env_path"
            [[ "$DOTENV_CURRENT" == "$env_path" ]] && _dotenv_unload
            ;;
        reload)
            [[ -n "$DOTENV_CURRENT" ]] && _dotenv_unload
            _dotenv_check
            ;;
        status)
            if [[ -n "$DOTENV_CURRENT" ]]; then
                echo "dotenv: loaded $DOTENV_CURRENT"
            else
                echo "dotenv: no .env loaded"
            fi
            ;;
        off)
            # Disable dotenv for this shell session
            _dotenv_unload
            chpwd_functions=(${chpwd_functions:#_dotenv_check})
            echo "dotenv: disabled for this session"
            ;;
        on)
            # Re-enable dotenv for this shell session
            if (( ! ${chpwd_functions[(I)_dotenv_check]} )); then
                chpwd_functions=($chpwd_functions _dotenv_check)
            fi
            _dotenv_check
            echo "dotenv: enabled"
            ;;
        *)
            echo "Usage: dotenv [allow|deny|reload|status|on|off] [path]"
            echo ""
            echo "Commands:"
            echo "  allow [path]  - Allow and load the .env file"
            echo "  deny [path]   - Deny the .env file"
            echo "  reload        - Reload the current .env"
            echo "  status        - Show current dotenv status"
            echo "  on            - Enable automatic .env loading"
            echo "  off           - Disable automatic .env loading"
            ;;
    esac
}

# Add hook to zsh using chpwd_functions (triggered on directory change)
# Only add if not already present
if (( ! ${chpwd_functions[(I)_dotenv_check]} )); then
    chpwd_functions=($chpwd_functions _dotenv_check)
fi

# Initial load for current directory
_dotenv_check