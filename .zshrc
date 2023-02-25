#!/bin/sh

# Profile
export LANG="en_US.UTF-8"
export EDITOR="code"
export VISUAL="code"
export GIT_EDITOR="code --wait"

# Binaries
export PATH="$PATH:$HOME/.bin:./bin:./.bin:$HOME/.local/bin:/usr/local/sbin"

# Homebrew
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

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
UPDATE_ZSH_DAYS=7

zle_highlight+=(paste:none) # disable text highlight on paste
zstyle ':bracketed-paste-magic' active-widgets '.self-*' # avoid slow pasting
zstyle ':completion:*' list-dirs-first true # list directories first
zstyle ':omz:update' mode auto # autoupdate omz

# Cache
autoload -Uz compinit
[[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]] && compinit || compinit -C

plugins=(
  colored-man-pages
  colorize
  fnm
  gh
  git-auto-fetch
  gitfast
  last-working-dir
  rbenv
  # From zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  # Custom from ~/.zsh
  brewfile
  colors256
  env-latest
  gatekeeper
  google
  node-modules
  xcode-reset
)

. "$ZSH/oh-my-zsh.sh"

# Git
[[ ! -f "$HOME/.gitprofile" ]] && touch "$HOME/.gitprofile" # private git profile
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"

# Node.js
export PATH="$PATH:./node_modules/.bin"
# fnm
if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi
# nvm
if command -v nvm >/dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" --no-use
  [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
fi

# Ruby
export PATH="$PATH:$HOME/.rbenv/bin"
if command -v rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PATH:$PYENV_ROOT/bin"
if command -v pyenv >/dev/null; then
  eval "$(pyenv init -)"
fi

# Avoid duplicates in PATH
typeset -aU path

# Load aliases and run cron jobs
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"
[[ -f "$HOME/.crontab" ]] && crontab "$HOME/.crontab"
