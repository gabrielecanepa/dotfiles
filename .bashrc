# Load RVM
export PATH="$PATH:$HOME/.rvm/bin"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Load rbenv
export PATH="$PATH:$HOME/.rbenv/bin"
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Use local bin folder to store binstubs
export PATH="$PATH:./bin:./node_modules/.bin:/usr/local/sbin"
