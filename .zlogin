# TODO: bundle scripts and remove next lines
for file in ~/Code/dotfiles/.scripts/**/*; do . $file; done
check_profile_installation

# Source aliases and custom scripts
[ -f $HOME/.aliases ] && . $HOME/.aliases
if [ -f $HOME/.scripts ]; then
  . $HOME/.scripts
  check_profile_installation
fi
