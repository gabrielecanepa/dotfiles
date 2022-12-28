#!/bin/sh

# Profile
export LANG="en_US.UTF-8"
export EDITOR="code"
export VISUAL="$EDITOR"
export GIT_EDITOR="code --wait"

# Mac preferences
export CLOUD="/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs"
export MACPREFS_BACKUP_DIRS=("$HOME/.macprefs" "$CLOUD/MacPrefs")

# Oh My Zsh - https://github.com/robbyrussell/oh-my-zsh/wiki
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME="squanchy"
ZSH_THEME_RPROMPTS=(node ruby python)
ZSH_COMPDUMP="$HOME/.zcompdump"

# Options
CASE_SENSITIVE=0
COMPLETION_WAITING_DOTS=0
DISABLE_AUTO_TITLE=0
DISABLE_AUTO_UPDATE=1
DISABLE_LS_COLORS=0
DISABLE_UNTRACKED_FILES_DIRTY=0
ENABLE_CORRECTION=0
HIST_STAMPS="yyyy-mm-dd"
HYPHEN_INSENSITIVE=0
UPDATE_ZSH_DAYS=3
UPDATE_ZSH_EXTEND=(brew yarn plugins)

zle_highlight+=(paste:none) # disable text highlight on paste
zstyle ':bracketed-paste-magic' active-widgets '.self-*' # avoid slow pasting
zstyle ':omz:update' mode auto # autoupdate omz

# Cache
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
	compinit
else
	compinit -C
fi;

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
  macprefs
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
export HOMEBREW_BUNDLE_FILE="$HOME/.Brewfile"
export HOMEBREW_BUNDLE_BREW_SKIP=0
export HOMEBREW_BUNDLE_CASK_SKIP=0
export HOMEBREW_BUNDLE_MAS_SKIP=1
export HOMEBREW_BUNDLE_WHALEBREW_SKIP=0
export HOMEBREW_BUNDLE_TAP_SKIP=0
export HOMEBREW_BUNDLE_NO_LOCK=0

# Node.js
export PATH="$PATH:./node_modules/.bin"
if type -a nvm >/dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" --no-use
  [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
fi

# Ruby
export PATH="$PATH:$HOME/.rbenv/bin"
if type -a rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PATH:$PYENV_ROOT/bin"
if type -a pyenv >/dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# PHP
export PATH="$PATH:$HOME/.composer/vendor/bin"

# Check setup using the profile plugin
type -a profile >/dev/null && ! profile check && return 1

# Load aliases
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"

# Set cron jobs
[[ -f "$HOME/.crontab" ]] && crontab "$HOME/.crontab"
