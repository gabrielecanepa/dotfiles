#!/bin/zsh

if [[ -z "$NAME" && -z "$EMAIL" ]]; then
  # Redirect to default profile.
  [[ -f ~/.profile ]] && . ~/.profile
fi
