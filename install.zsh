#!/bin/zsh

# TODO: install/check dependencies
# - MacOS + git etc.
# - Oh My Zsh
# - zsh plugins
# - rbenv
# - nvm
# - NerdFonts for zsh themes

# Install profile
. .scripts/ext/echo
. .scripts/profile
profile install

# Initialize repository
rm -rf .git
git init
git add .
git commit -m "Initialize new configuration for $USER"
