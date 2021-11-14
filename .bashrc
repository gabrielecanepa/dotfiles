#!/bin/bash

# Ruby - load rbenv
PATH="$PATH:$HOME/.rbenv/bin"
if type -a rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi

# Node - load nvm
if type -a nvm >/dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
fi

# Other binstubs + aliases
export PATH="$PATH:./bin:./node_modules/.bin:$HOME/.bin"
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"
