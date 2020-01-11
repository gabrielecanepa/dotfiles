# Oh My Zsh: https://github.com/robbyrussell/oh-my-zsh/wiki
ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbierussell" # https://github.com/gabrielecanepa/robbierussell

plugins=(
  brew
  colored-man-pages
  colorize
  gem
  github
  last-working-dir
  nvm
  rbenv
  sublime
  themes
  zsh-autosuggestions
  zsh-syntax-highlighting
)

. "$ZSH/oh-my-zsh.sh"

# Ruby: load rbenv
if (type -a rbenv >/dev/null); then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "`rbenv init -`"
fi

# Node: load nvm
if (type -a nvm >/dev/null); then
  export NVM_DIR="$HOME/.nvm"
  . "$NVM_DIR/nvm.sh" --no-use
fi

# Other binstubs and aliases
export PATH="$PATH:./bin:./node_modules/.bin:$HOME/.bin"
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"
