#!/bin/sh

# Profile
export LANG="en_US.UTF-8"
export EDITOR="code"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR --wait"

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
zstyle ':completion:*' list-dirs-first true # list directories first
zstyle ':omz:update' mode auto # autoupdate omz

# Cache
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
	compinit
else
	compinit -C
fi

plugins=(
  colored-man-pages
  colorize
  gh
  git-auto-fetch
  gitfast
  last-working-dir
  rbenv
  themes
  # From zsh users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  # Custom from ~/.zsh
  brewfile
  colors256
  gatekeeper
  google
  node_modules
  xcode-select
)

. "$ZSH/oh-my-zsh.sh"

# Homebrew
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

if ! type -a brew >/dev/null; then
  echo "$(/opt/homebrew/bin/brew shellenv)" >> /Users/$USER/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Git
[[ ! -f "$HOME/.gitprofile" ]] && touch "$HOME/.gitprofile" # private git profile
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"

# Binaries
PATH="$PATH:$HOME/.bin:./bin:./.bin:$HOME/.local/bin:/usr/local/sbin"

# Node.js
PATH="$PATH:./node_modules/.bin"
if type -a fnm >/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi
if type -a nvm >/dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" --no-use
  [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
fi

# Ruby
if type -a rbenv >/dev/null; then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "$(rbenv init -)"
fi

# Python
if type -a pyenv >/dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  PATH="$PATH:$PYENV_ROOT/bin"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

typeset -aU path # avoid duplicates in PATH
export PATH

# Load aliases and run cron jobs
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"
[[ -f "$HOME/.crontab" ]] && crontab "$HOME/.crontab"
