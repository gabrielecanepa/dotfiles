#!/bin/zsh

# Environment
export LANG="en_US.UTF-8"

# Binaries
export PATH="./node_modules/.bin:/usr/local/sbin:$PATH"

# Homebrew (https://brew.sh)
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar";
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX";
export HOMEBREW_NO_INSTALL_FROM_API=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH+:$PATH}";
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}";

# Git (https://git-scm.com)
[[ ! -f "$HOME/.gitprofile" ]] && touch "$HOME/.gitprofile"
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"
export FILTER_BRANCH_SQUELCH_WARNING=1

# Version managers
# nodenv (https://github.com/nodenv/nodenv)
# pyenv (https://github.com/pyenv/pyenv)
# rbenv (https://github.com/rbenv/rbenv)
for vm in nodenv pyenv rbenv; do
  ! command -v $vm >/dev/null && continue
  export ${vm:u}_ROOT="$HOME/.${vm}"
  export PATH="$(eval "echo $"${vm:u}_ROOT"")/bin:$PATH"
  eval "$(${vm} init --path - zsh)"
done; unset vm

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
[[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]] && compinit || compinit -C

# Plugins
plugins=(
  colored-man-pages
  colorize
  gh
  git-auto-fetch
  gitfast
  last-working-dir
  nodenv
  pyenv
  rbenv
  # From zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  # Custom from ~/.zsh
  colors256
  dependencies
  gatekeeper
  gh-run
  google
  homebrew
  lts
  node-modules
  node-version
  npm-global
  path
  profile
  xcode-reset
  yarn@1
)

. "$ZSH/oh-my-zsh.sh"

# Check profile installation.
command -v profile >/dev/null && ! profile check && return 1

# Export global variables.
export VSCODE_CUSTOM="$HOME/.vscode/user"

# Load aliases.
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"
# Run background jobs
[[ -f "$HOME/.jobs" ]] && (. "$HOME/.jobs" >/dev/null &) >/dev/null
# Run cronjobs.
[[ -f "$HOME/.crontab" ]] && crontab "$HOME/.crontab"

# Avoid duplicates in PATH.
typeset -aU path
