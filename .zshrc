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
HOMEBREW_NO_ANALYTICS=1

# Load Oh My Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm

# Load rbenv
PATH="$PATH:$HOME/.rbenv/bin"
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Use local bin folder to store binstubs
export PATH="$PATH:./bin:./node_modules/.bin:/usr/local/sbin"

# Load local profile
source "$HOME/.profile"
source "$HOME/.aliases"
source <(cat $HOME/.scripts/*)

# Encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export BUNDLER_EDITOR="$TEXT_EDITOR -a $@ > /dev/null"
