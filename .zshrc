#!/bin/sh

# Profile
export LANG="en_US.UTF-8"
export EDITOR="code"
export VISUAL="$EDITOR"
export GIT_EDITOR="code --wait"
# NAME EMAIL WORKING_DIR in ~/.zprofile

# Oh My Zsh - https://github.com/robbyrussell/oh-my-zsh/wiki
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME="squanchy"
ZSH_THEME_RPROMPTS=(nvm ruby python)
ZSH_COMPDUMP="$HOME/.zcompdump"

# Options
CASE_SENSITIVE="false"
COMPLETION_WAITING_DOTS="false"
DISABLE_AUTO_TITLE="false"
DISABLE_AUTO_UPDATE="true"
DISABLE_LS_COLORS="false"
DISABLE_UNTRACKED_FILES_DIRTY="false"
ENABLE_CORRECTION="false"
HIST_STAMPS="yyyy-mm-dd"
HYPHEN_INSENSITIVE="false"
UPDATE_ZSH_DAYS=3
UPDATE_ZSH_EXTEND=(brew yarn plugins)

autoload -U compinit && compinit # reload completions
zle_highlight+=(paste:none) # disable text highlight on paste
zstyle ':bracketed-paste-magic' active-widgets '.self-*' # fix slow pasting
zstyle ':omz:update' mode auto # auto update omz

plugins=(
  colored-man-pages
  colorize
  gh
  git-auto-fetch
  gitfast
  last-working-dir
  macos
  nvm
  rails
  rbenv
  themes
  # From https://github.com/zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  # Custom
  brewfile
  colors256
  gatekeeper
  google
  node_modules
  profile
  uptodate
  xcode-select
)

. "$ZSH/oh-my-zsh.sh"

# Binaries
export PATH="$PATH:$HOME/.bin:$HOME/.local/bin:/usr/local/sbin:./bin:./.bin"
typeset -aU path

# Git
[[ ! -f "$HOME/.gitprofile" ]] && touch "$HOME/.gitprofile" # private git profile
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Homebrew
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# Node.js
export PATH="$PATH:./node_modules/.bin"
if type -a nvm > /dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" --no-use
  [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
fi

# Ruby
export PATH="$PATH:$HOME/.rbenv/bin"
if type -a rbenv > /dev/null; then
  eval "$(rbenv init -)"
fi

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PATH:$PYENV_ROOT/bin"
if type -a pyenv > /dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# PHP
export PATH="$PATH:$HOME/.composer/vendor/bin"

# Check setup with the `profile` plugin
type -a profile > /dev/null && ! profile check && return 1

# Load aliases
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"

# Set cron jobs
[[ -f "$HOME/.crontab" ]] && crontab "$HOME/.crontab"
