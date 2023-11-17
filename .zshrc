#!/bin/zsh

export LANG="en_US.UTF-8"

# Binaries
export PATH="$PATH:$HOME/.bin:./bin:./.bin:$HOME/.local/bin:/usr/local/sbin"

# Homebrew (https://brew.sh)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export HOMEBREW_NO_INSTALL_FROM_API=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# Oh My Zsh (https://ohmyz.sh)
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME="squanchy"
ZSH_THEME_SQUANCHY_RPROMPTS=(node ruby python)
ZSH_COMPDUMP="$HOME/.zcompdump"

# Options
CASE_SENSITIVE=0
COMPLETION_WAITING_DOTS=""
DISABLE_AUTO_TITLE=0
DISABLE_AUTO_UPDATE=1
DISABLE_LS_COLORS=0
DISABLE_UNTRACKED_FILES_DIRTY=0
ENABLE_CORRECTION=0
HIST_STAMPS="yyyy-mm-dd"
HYPHEN_INSENSITIVE=0
UPDATE_ZSH_DAYS=7

zstyle ':completion:*' list-dirs-first true # list directories first
zstyle ':omz:update' mode auto # autoupdate omz
zstyle ':bracketed-paste-magic' active-widgets '.self-*' # fix slow paste
zle_highlight+=(paste:none) # disable text highlight on paste

# Completion
autoload -Uz compinit
[[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]] && compinit || compinit -C # optimize caches

# Plugins
plugins=(
  colored-man-pages
  colorize
  gh
  git-auto-fetch
  gitfast
  last-working-dir
  nodenv
  rbenv
  # From zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  # Custom from ~/.zsh
  colors256
  dependencies
  gatekeeper
  gh+
  google
  homebrew
  lts
  node-modules
  node-version
  profile
  xcode-reset
  yarn+
)

. "$ZSH/oh-my-zsh.sh"

# Check profile installation.
command -v profile >/dev/null && ! profile check && return 1

# Git (https://git-scm.com)
export FILTER_BRANCH_SQUELCH_WARNING=1
[[ ! -f "$HOME/.gitprofile" ]] && touch "$HOME/.gitprofile" # use private git profile
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"

# Node.js - nodenv (https://github.com/nodenv)
command -v nodenv >/dev/null && eval "$(nodenv init - zsh)"
# npm (https://npmjs.com)
export PATH="$PATH:./node_modules/.bin:$(npm get prefix)/bin"

# Bun (https://bun.sh)
export BUN_INSTALL="$HOME/.bun"
export PATH="$PATH:$BUN_INSTALL/bin"
[[ -f "$BUN_INSTALL/_bun" ]] && . "$BUN_INSTALL/_bun"

# Ruby - rbenv (https://github.com/rbenv)
command -v rbenv >/dev/null && eval "$(rbenv init - zsh)"

# Python - pyenv (https://github.com/pyenv)
command -v pyenv >/dev/null && eval "$(pyenv init - zsh)"

# Define global variables.
export VSCODE_CUSTOM=~/.vscode/user

# Load aliases.
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"
# Run background jobs
[[ -f "$HOME/.jobs" ]] && (. "$HOME/.jobs" >/dev/null &) >/dev/null
# Run cronjobs.
[[ -f "$HOME/.crontab" ]] && crontab "$HOME/.crontab"

# Avoid duplicates in PATH.
typeset -aU path
