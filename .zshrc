# Oh My Zsh: https://github.com/robbyrussell/oh-my-zsh/wiki
ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbierussell"

plugins=(
  brew
  colored-man-pages
  colorize
  cp
  gem
  github
  nvm
  osx
  rbenv
  sublime
  themes
  zsh-autosuggestions
  zsh-navigation-tools
  zsh-syntax-highlighting
)

. "$ZSH/oh-my-zsh.sh"

# Zsh: http://zsh.sourceforge.net/Docs
setopt RC_EXPAND_PARAM

# Ruby: load rbenv and set Bundler editor
if (type -a rbenv >/dev/null); then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "`rbenv init -`"
fi
[ $EDITOR ] && export BUNDLER_EDITOR="$EDITOR"

# Node: load nvm
if [ -s "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
  . "$NVM_DIR/nvm.sh" --no-use
fi

# Use local folder for binstubs
export PATH="$PATH:./bin:/usr/local/sbin:./node_modules/.bin"
