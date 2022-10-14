#!/bin/sh

export LANG=en_US.UTF-8

# Oh My Zsh (https://github.com/robbyrussell/oh-my-zsh/wiki)
ZSH="$HOME/.oh-my-zsh"

ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME="squanchy"
ZSH_COMPDUMP="$HOME/.zcompdump"
ZSH_THEME_RPROMPTS=(nvm ruby python) # squanchy theme rprompts

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
  # Custom
  brewfile
  colors256
  gatekeeper
  google
  node_modules
  profile
  xcode-select
  # From zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

. "$ZSH/oh-my-zsh.sh"

# Check profile installation
type -a profile > /dev/null && ! profile check && return 1

# Git
[ ! -f "$HOME/.gitprofile" ] && touch "$HOME/.gitprofile" # use private .gitprofile file
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" core.editor "$GIT_EDITOR"

# Homebrew
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# nvm
if type -a nvm > /dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # load completion
fi

# rbenv
PATH="$PATH:$HOME/.rbenv/bin"
if type -a rbenv > /dev/null; then
  eval "$(rbenv init -)"
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
PATH="$PATH:$PYENV_ROOT/bin"
if type -a pyenv > /dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# Binaries
export PATH="$PATH:$HOME/.bin:/usr/local/sbin:./bin:./node_modules/.bin:$HOME/.composer/vendor/bin"
typeset -aU path # avoid duplicates

# Aliases
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"
