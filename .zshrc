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
HOMEBREW_NO_ANALYTICS=1

# Load Oh My Zsh
. "$ZSH/oh-my-zsh.sh"
unalias rm

# Load rbenv
if (type -a rbenv > /dev/null); then
  PATH="$PATH:$HOME/.rbenv/bin"
  eval "$(rbenv init -)"
fi

# Use local bin folder to store binstubs
export PATH="$PATH:./bin:/usr/local/sbin:./node_modules/.bin"

# Load profile, aliases, and custom scripts
. "$HOME/.profile"
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"
[ -d "$HOME/.scripts" ] && for script in ~/.scripts/**/*; do . $script; done

# Encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# git
export FILTER_BRANCH_SQUELCH_WARNING=1

# Bundler
export BUNDLER_EDITOR=$TEXT_EDITOR
