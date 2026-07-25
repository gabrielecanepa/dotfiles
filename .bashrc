#!/usr/bin/env bash

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv bash)"

case $- in
  *i*) ;;
  *) return ;;
esac

if command -v zsh >/dev/null; then
  SHELL="$(command -v zsh)"
  export SHELL
  exec "$SHELL" -l
fi
