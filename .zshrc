#!/bin/sh

# Profile
export LANG="en_US.UTF-8"
export EDITOR="code-insiders"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR --wait"

# Binaries
export PATH="$PATH:$HOME/.bin:./bin:./.bin:$HOME/.local/bin:/usr/local/sbin"

# Homebrew - https://brew.sh
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# Oh My Zsh - https://ohmyz.sh
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

# Git - https://git-scm.com
[[ ! -f "$HOME/.gitprofile" ]] && touch "$HOME/.gitprofile" # use private git profile
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"

# fnm - https://github.com/Schniz/fnm
export PATH="$PATH:./node_modules/.bin"
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd)"

# rbenv - https://github.com/rbenv/rbenv
export PATH="$PATH:$HOME/.rbenv/bin"
command -v rbenv >/dev/null && eval "$(rbenv init - zsh)"

# pyenv - https://github.com/pyenv/pyenv
export PATH="$PATH:$HOME/.pyenv/bin"
command -v pyenv >/dev/null && eval "$(pyenv init - zsh)"

# Avoid duplicates in PATH
typeset -aU path

# Load aliases and run cron jobs
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"
crontab -l &>/dev/null && return 0 || crontab "$HOME/.crontab.reboot"
