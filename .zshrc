#!/bin/zsh

# Environment
export LANG="en_US.UTF-8"

# Binaries
export PATH="$PATH:/usr/local/sbin:./bin:./node_modules/.bin"

# Homebrew (https://brew.sh)
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
export HOMEBREW_NO_INSTALL_FROM_API=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH+:$PATH}"
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}" 
export FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

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
ZSH_THEME_SQUANCHY_LANGS=(node ruby python)
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

zstyle ':completion:*' list-dirs-first true
zstyle ':omz:update' mode auto
zstyle ':bracketed-paste-magic' active-widgets '.self-*'
zle_highlight+=(paste:none)

# Completions
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
  # Custom
  brewfile
  gh-run
  lts
  node-version
  npm-global
  path
  plugin
  profile
  xcode-reset
  yarn1
)
lazy_plugins=(
  colors256
  dependencies
  gatekeeper
  google
  node-modules
)

. "$ZSH/oh-my-zsh.sh"

# Check profile
type profile &>/dev/null && ! profile check && return 1

# Git (https://git-scm.com)
[[ ! -f "$HOME/.gitprofile" ]] && touch "$HOME/.gitprofile"
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"
export FILTER_BRANCH_SQUELCH_WARNING=1

# Load aliases
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"
# Run background jobs
[[ -f "$HOME/.jobs" ]] && (. "$HOME/.jobs" >/dev/null &) >/dev/null
# Run cronjobs
[[ -f "$HOME/.crontab" ]] && crontab "$HOME/.crontab"

# Remove duplicates from path
typeset -aU path
