#!/bin/bash

# Backup to zsh
if type -a zsh &/dev/null; then
  export SHELL=/bin/zsh
  exec zsh
fi
