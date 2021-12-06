#!/bin/zsh

export LANG=en_US.UTF-8

# Oh My Zsh: https://github.com/robbyrussell/oh-my-zsh/wiki
ZSH="$HOME/.oh-my-zsh"

ZSH_CUSTOM="$HOME/.zsh"
ZSH_THEME="squanchy"

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
UPDATE_ZSH_DAYS=1

plugins=(
  brew
  colored-man-pages
  colorize
  gem
  github
  last-working-dir
  nvm
  rails
  rbenv
  themes
  # Custom
  brewfile
  gatekeeper
  google
  node_modules
  xcode-select
  # From zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

. "$ZSH/oh-my-zsh.sh"

# Zsh
autoload -U compinit && compinit # reload completions
zstyle ':bracketed-paste-magic' active-widgets '.self-*' # fix slow pasting
zstyle ':omz:update' mode auto # auto update omz
zle_highlight+=(paste:none) # disable text highlight on paste

# git
[ ! -f "$HOME/.gitprofile" ] && touch "$HOME/.gitprofile" # use private .gitprofile file
git config --file "$HOME/.gitprofile" user.email "$EMAIL"
git config --file "$HOME/.gitprofile" user.name "$NAME"
git config --file "$HOME/.gitprofile" core.editor "$EDITOR --wait"
export FILTER_BRANCH_SQUELCH_WARNING=1

# Homebrew
export HOMEBREW_NO_ANALYTICS=1

# nvm
if type -a nvm > /dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
fi
# rbenv
if type -a rbenv > /dev/null; then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "$(rbenv init -)"
fi
# pyenv
if type -a pyenv > /dev/null; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  export PYENV_VIRTUALENV_DISABLE_PROMPT=1
fi

# Binstubs
PATH="$PATH:/usr/local/sbin:./bin:./node_modules/.bin:$HOME/.composer/vendor/bin"

# Aliases
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"

# Export $PATH
export PATH="$HOME/bin:$PATH"
typeset -aU path # avoid duplicates
