# TODO: speed up nvm or use fnm

ZSH="$HOME/.oh-my-zsh"

# Options - http://zsh.sourceforge.net/Doc/Release/Options.html#Description-of-Options
setopt RC_EXPAND_PARAM

# Theme - https://github.com/robbyrussell/oh-my-zsh/wiki/themes
export ZSH_THEME="robbyrussell"

# Plugins - https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins
export plugins=(
  brew
  bundler
  colored-man-pages
  common-aliases
  gatsby
  gem
  git
  git-extras
  github
  heroku
  npm
  osx
  redis-cli
  web-search
  yarn
  zsh-autosuggestions
  zsh-navigation-tools
  zsh-syntax-highlighting
)
export HOMEBREW_NO_ANALYTICS=1 # prevent Homebrew from reporting

# Load Oh My Zsh
. "$ZSH/oh-my-zsh.sh"

# Ruby: load rbenv and set Bundler editor
if (type -a rbenv >/dev/null); then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "`rbenv init -`"
fi
[ $EDITOR ] && export BUNDLER_EDITOR="$EDITOR"

# Node: load nvm
NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh" --no-use
fi

# Use local bin folder for binstubs
export PATH="$PATH:./bin:/usr/local/sbin:./node_modules/.bin"
