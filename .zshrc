#!/bin/sh

export LANG=en_US.UTF-8

# Oh My Zsh (https://github.com/robbyrussell/oh-my-zsh/wiki)
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME="squanchy"
ZSH_THEME_RPROMPTS=(nvm ruby python)
ZSH_COMPDUMP="$HOME/.zcompdump"

# Options
CASE_SENSITIVE="false"
COMPLETION_WAITING_DOTS="false"
DISABLE_AUTO_TITLE="false"
DISABLE_AUTO_UPDATE="false"
DISABLE_LS_COLORS="false"
DISABLE_UNTRACKED_FILES_DIRTY="false"
ENABLE_CORRECTION="false"
HIST_STAMPS="yyyy-mm-dd"
HYPHEN_INSENSITIVE="false"
UPDATE_ZSH_DAYS=7

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
  xcode-select
)

. "$ZSH/oh-my-zsh.sh"

# Binaries
export PATH="$PATH:$HOME/.bin:/usr/local/sbin:./bin:./.bin"
typeset -aU path

# Check profile installation
type -a profile > /dev/null && ! profile check && return 1

# Git
[[ ! -f "$HOME/.gitprofile" ]] && touch "$HOME/.gitprofile" # private .gitprofile
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

# Aliases
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"
