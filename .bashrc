#!/bin/bash

export LANG=en_US.UTF-8

# git
[ ! -f "$HOME/.gitprofile" ] && touch "$HOME/.gitprofile" # use .gitprofile file
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" core.editor "$EDITOR --wait"
export FILTER_BRANCH_SQUELCH_WARNING=1

# Homebrew
export HOMEBREW_NO_ANALYTICS=1

# nvm
if type -a nvm > /dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
fi
# rbenv
if type -a rbenv > /dev/null; then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "$(rbenv init -)"
fi
# pyenv
if type -a pyenv > /dev/null; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  export PYENV_VIRTUALENV_DISABLE_PROMPT=1
fi

# Binstubs
PATH="$PATH:/usr/local/sbin:./bin:./node_modules/.bin:$HOME/.composer/vendor/bin"

# Aliases
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"

# Export $PATH
export PATH="$HOME/bin:$PATH"
typeset -aU path # avoid duplicates
