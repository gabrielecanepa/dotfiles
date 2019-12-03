# Backup Ruby to RVM
if ! (type -a rbenv > /dev/null) && [ -s "$HOME/.rvm/scripts/rvm" ]; then
  export PATH="$PATH:$HOME/.rvm/bin"
  . "$HOME/.rvm/scripts/rvm"
fi
