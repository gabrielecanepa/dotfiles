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
. "${ZSH}/oh-my-zsh.sh"
unalias rm

# Load rbenv
PATH="$PATH:$HOME/.rbenv/bin"
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Use local bin folder to store binstubs
PATH="$PATH:./bin:./node_modules/.bin:/usr/local/sbin"

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"

# Load Anaconda
export PATH="$PATH:/anaconda3/bin:$HOME/anaconda3/bin"

# Load local profile
. "$HOME/.profile"
. "$HOME/.aliases"
[ -d "$HOME/.scripts" ] && . <(cat $HOME/.scripts/*)

# Use default editor for bundler
export BUNDLER_EDITOR=$TEXT_EDITOR

# Encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
