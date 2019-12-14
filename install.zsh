#!/bin/zsh

# TODO: add/check installations

# Install profile
. .scripts/ext/echo
. .scripts/profile
profile install

# Initialize repository
rm -rf .git
git init
git add .
git commit -m "Initialize new config for $USER"
