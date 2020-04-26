# Oh My Zsh - https://github.com/robbyrussell/oh-my-zsh/wiki
ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="squanchy" # https://github.com/gabrielecanepa/zsh-theme

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
  sublime
  themes
  # Ext
  zsh-autosuggestions # disable when sharing screen 😬
  zsh-completions
  zsh-syntax-highlighting
  # Custom - https://github.com/gabrielecanepa/zsh-plugins
  gatekeeper
  node-modules
  profile
)

. "$ZSH/oh-my-zsh.sh"

zstyle ":bracketed-paste-magic" active-widgets ".self-*" # fix slow pasting
zle_highlight+=(paste:none) # disable text highlight on paste

# Load rbenv
PATH="$PATH:$HOME/.rbenv/bin"
if type -a rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi
export RUBYOPT="-W:no-deprecated" # suppress deprecation warnings

# Load nvm
if type -a nvm >/dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
fi

# Other binstubs + aliases
export PATH="$PATH:/usr/local/sbin:./bin:./node_modules/.bin"
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"

# Check profile installation
profile >/dev/null && profile check

# Avoid duplicates in $PATH
typeset -aU path
