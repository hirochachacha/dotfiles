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

gocd(){ cd $(find $(go env GOPATH)/src $(go env GOROOT)/src -type d -name .hg -prune -o -type d -name .git -prune -o -type d -name .bzr -prune -o -type d -name "$1" -print | peco --select-1 || echo $PWD); }

alias j=z
alias cd=z
alias vi=nvim
alias cat=bat
alias find=fd
alias ag=ripgrep

eval "$(zoxide init bash)"
eval "$(starship init bash)"

source <(fzf --bash)

#
# Local configuration file.
#

if [[ -f "$HOME/.bashrc.local" ]]; then
  source "$HOME/.bashrc.local"
fi
