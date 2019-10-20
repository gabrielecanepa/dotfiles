ZSH="$HOME/.oh-my-zsh"

# Theme - https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="robbyrussell"

# Plugins - https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins
plugins=(
  common-aliases
  gatsby
  gem
  git-extras
  gitfast
  github
  heroku
  history-substring-search
  last-working-dir
  sublime
  zsh-syntax-highlighting
)

# Prevent Homebrew from reporting
export HOMEBREW_NO_ANALYTICS=1

# Load Oh My Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm

# Local profile
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile"
[[ -s "$HOME/.aliases" ]] && source "$HOME/.aliases"
for filename in $HOME/.scripts/**/*; do [[ -f $filename ]] && source $filename; done

# Encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export BUNDLER_EDITOR="$TEXT_EDITOR $@ >/dev/null 2>&1 -a"

# Setup git
git config --global core.editor "$TEXT_EDITOR -n -w >/dev/null 2>&1"
if ! git config --global core.excludesfile > /dev/null; then git config --global core.excludesfile "$HOME/.gitignore*"; fi
git config --global user.email $EMAIL
git config --global user.name $NAME
