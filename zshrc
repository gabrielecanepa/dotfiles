ZSH=$HOME/.oh-my-zsh

# Change theme - https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="robbyrussell"

# Useful plugins
plugins=(gitfast last-working-dir common-aliases sublime zsh-syntax-highlighting history-substring-search)

# Prevent Homebrew from reporting - https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/Analytics.md
export HOMEBREW_NO_ANALYTICS=1

# Load Oh-My-Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm

# Load rbenv if installed
export PATH="${HOME}/.rbenv/bin:${PATH}"
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Use local `bin` folder to store binstubs
export PATH="./bin:./node_modules/.bin:${PATH}:/usr/local/sbin"

# Store aliases in ~/.aliases file and load them here
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Encoding for the terminal
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export BUNDLER_EDITOR="atom $@ >/dev/null 2>&1 -a"
