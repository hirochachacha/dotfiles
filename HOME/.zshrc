gemcd(){
  cd $(ruby -e "
name = \"$1\"
begin
  print Gem::Specification.find_by_name(name).full_gem_path
rescue Gem::LoadError
  \$LOAD_PATH.each do |load_path|
    if File.exist?(\"#{load_path}/#{name}\")
      print \"#{load_path}/#{name}\"
      exit
    elsif File.exist?(\"#{load_path}/#{name}.rb\")
      print \"#{load_path}/#{name}.rb\".split('/')[0...-1].join('/')
      exit
    end
  end
  print Dir.getwd
end
  ");
}

pycd(){
  cd $(python -c "
import os
try:
    import $1
except ImportError:
    print(os.getcwd())
    exit()
else:
    print(os.path.dirname($1.__file__))
  ");
}

denocd() {
  cd $(\find $(deno info --json | jq -r .denoDir) -type d -name .hg -prune -o -type d -name .git -prune -o -type d -name .bzr -prune -o -type d -name "$1" -print | fzf --select-1 || echo $PWD);
}

gocd(){
  cd $(\find $(go env GOPATH)/src $(go env GOROOT)/src -type d -name .hg -prune -o -type d -name .git -prune -o -type d -name .bzr -prune -o -type d -name "$1" -print | fzf --select-1 || echo $PWD);
}

setopt inc_append_history
setopt share_history
setopt autocd
setopt complete_aliases
setopt hist_ignore_space
setopt hist_ignore_dups

WORDCHARS=${WORDCHARS/\/}
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTORY_IGNORE="(history|pwd|exit|ls|ls *|j *)"

zshaddhistory() {
  emulate -L zsh
  [[ ${1%%$'\n'} != ${~HISTORY_IGNORE} ]]
}

bindkey -e
bindkey \^U backward-kill-line

magic-enter(){
  if [[ -z $BUFFER ]]
  then
    printf "\033[H\033[2J" && eza --icons --git --time-style relative -snew -G -l
    # clear && ls -l
  else
  fi

  zle accept-line
}

zle -N magic-enter

bindkey "^M" magic-enter

alias j=z
alias cd=z
alias vi=nvim
alias cat=bat
alias find=fd
alias ag=rg

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

source <(fzf --zsh)

#
# Local configuration file.
#

if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
