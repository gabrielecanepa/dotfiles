#!/bin/zsh

# Oh My Zsh - https://github.com/robbyrussell/oh-my-zsh
ZSH="$HOME/.oh-my-zsh"

# Theme - https://github.com/robbyrussell/oh-my-zsh/wiki/themes
export ZSH_THEME="robbyrussell"

# Plugins - https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins
export plugins=(
  brew
  bundler
  common-aliases
  gatsby
  gem
  git
  git-extras
  gitfast
  github
  heroku
  history
  npm
  osx
  redis-cli
  web-search
  yarn
  zsh-syntax-highlighting
)
export HOMEBREW_NO_ANALYTICS=1 # prevents Homebrew from reporting

. "$ZSH/oh-my-zsh.sh"
unalias rm

# Profile
. "$HOME/.profile"
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"
[ -d "$HOME/.scripts" ] && for script in ~/.scripts/**/*; do . $script; done

# Encoding
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# git
export FILTER_BRANCH_SQUELCH_WARNING=1

# Ruby: load rbenv and set Bundler editor
if (type -a rbenv > /dev/null); then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "$(rbenv init -)"
fi
export BUNDLER_EDITOR="$TEXT_EDITOR"

# Node: load nvm
if [ -s "$NVM_DIR/nvm.sh" ]; then
  export NVM_DIR="$HOME/.nvm"
  . "$NVM_DIR/nvm.sh"
fi

# Rails: use local bin folder for binstubs
export PATH="$PATH:./bin:/usr/local/sbin:./node_modules/.bin"
