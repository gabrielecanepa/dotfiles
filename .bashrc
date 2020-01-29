#!/bin/bash

# Ruby: load rbenv or rvm
export PATH="$PATH:$HOME/.rbenv/bin"
if (type -a rbenv >/dev/null); then
  eval "$(rbenv init -)"
elif [ -s "$HOME/.rvm/scripts/rvm" ]; then
  export PATH="$PATH:$HOME/.rvm/bin"
  . "$HOME/.rvm/scripts/rvm"
fi

# Node: load nvm
export NVM_DIR="$HOME/.nvm"
if (type -a nvm >/dev/null); then
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi
