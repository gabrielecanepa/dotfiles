ZSH="$HOME/.oh-my-zsh"

# Theme - https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="robbyrussell"

# Plugins - https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins
plugins=(
  common-aliases
  gatsby
  gem
  git-extras
  gitfast
  github
  heroku
  history-substring-search
  last-working-dir
  sublime
  zsh-syntax-highlighting
)

# Prevent Homebrew from reporting
export HOMEBREW_NO_ANALYTICS=1

# Load Oh My Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm

# Load rbenv
export PATH="$PATH:$HOME/.rbenv/bin"
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Use local bin folder to store binstubs
export PATH="$PATH:./bin:./node_modules/.bin:/usr/local/sbin"

# Local profile
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile"
[[ -s "$HOME/.aliases" ]] && source "$HOME/.aliases"
for filename in $HOME/.scripts/**/*; do [[ -f $filename ]] && source $filename; done

# Encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export BUNDLER_EDITOR="$TEXT_EDITOR -a $@ > /dev/null"

# Setup git
git config --global core.editor "$TEXT_EDITOR -nw > /dev/null"
if ! git config --global core.excludesfile > /dev/null; then git config --global core.excludesfile "$HOME/.gitignore*"; fi
git config --global include.path "~/.gitconfig_global"
git config --global user.email $EMAIL
git config --global user.name $NAME
