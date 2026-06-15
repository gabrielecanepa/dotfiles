#!/bin/sh

[ -f "$HOME/.zprofile" ] && . "$HOME/.zprofile"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
