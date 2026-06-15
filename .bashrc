#!/bin/bash

if command -v zsh >/dev/null; then
  export SHELL=/bin/zsh
  exec zsh
fi

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
