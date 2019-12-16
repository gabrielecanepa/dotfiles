# TODO: bundle scripts and remove next lines
for file in ~/Code/dotfiles/.scripts/**/*; do . $file; done
check_profile_installation
[ $? = 0 ] && link_dotfiles

# Source aliases and custom scripts
[ -f $HOME/.aliases ] && . $HOME/.aliases
if [ -f $HOME/.scripts ]; then
  . $HOME/.scripts
  check_profile_installation
  [ $? = 0 ] && link_dotfiles
fi
