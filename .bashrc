#!/bin/bash

# Backup to zsh if available.
if command -v zsh >/dev/null; then
  export SHELL=/bin/zsh
  exec zsh
fi
