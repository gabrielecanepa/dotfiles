# Zsh
zstyle ':bracketed-paste-magic' active-widgets '.self-*' # fix slow pasting
zstyle ':omz:update' mode auto # auto update omz
zle_highlight+=(paste:none) # disable text highlight on paste
autoload -U compinit && compinit # reload completions

# Oh My Zsh: https://github.com/robbyrussell/oh-my-zsh/wiki
ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="squanchy"

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
  gatekeeper
  google
  node_modules
  # profile FIXME
  xcode-select
  # From zsh-users
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

. "$ZSH/oh-my-zsh.sh"

# git
export FILTER_BRANCH_SQUELCH_WARNING=1
# Homebrew
export HOMEBREW_NO_ANALYTICS=1

# Load nvm
if type -a nvm > /dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
fi

# Load rbenv
if type -a rbenv > /dev/null; then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "$(rbenv init -)"
fi

# Load pyenv
if type -a pyenv > /dev/null; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  export PYENV_VIRTUALENV_DISABLE_PROMPT=1
fi

# Binstubs
export PATH="$PATH:/usr/local/sbin:./bin:./node_modules/.bin:$HOME/.composer/vendor/bin"

# Load custom aliases
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"

# Avoid duplicates in $PATH
typeset -aU path

# Switch to last working directory
lwd
