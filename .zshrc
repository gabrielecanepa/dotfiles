# Oh My Zsh - https://github.com/robbyrussell/oh-my-zsh/wiki
ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="squanchy" # https://github.com/gabrielecanepa/squanchy

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
  # zsh-autosuggestions # disable when sharing screen, or weird things could appear 😁
  zsh-syntax-highlighting
)

. "$ZSH/oh-my-zsh.sh"

zstyle ':bracketed-paste-magic' active-widgets '.self-*' # fix slow pasting
zle_highlight+=(paste:none) # disable text highlight on paste

# Load rbenv
PATH="$PATH:$HOME/.rbenv/bin"
if type -a rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi

# Load nvm
if type -a nvm >/dev/null; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
fi

# Other binstubs + aliases
export PATH="$PATH:/usr/local/sbin:./bin:./node_modules/.bin:$WORKING_DIR/dotfiles/.zsh.tmp" # TODO: remove `.zsh.tmp` after closing issue #2
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"

# Check profile installation
type -a profile >/dev/null && profile check

# Avoid duplicates in $PATH
typeset -aU path
