#!/bin/zsh

brew() {
  case $1 in
    actualize)
      command brew update && command brew upgrade && command brew cleanup && command brew doctor
      ;;
    dump)
      command brew bundle dump ${@:2} --global --describe
      ;;
    init)
      if [  -f "$HOME/.Brewfile" ]; then
        printf "${fg[yellow]}Brewfile already exists. Do you want to override it? [y/N]$reset_color "
        read -r choice
        if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
          rm -f "$HOME/.Brewfile" "$HOME/.Brewfile.lock.json"
          brew dump
        fi
      else
        brew dump
      fi
      command brew bundle install --global --no-lock
      ;;
    # install|uninstall)
    #   command brew $@ && brew dump --force
    #   ;;
    *)
      command brew $@ && brew dump --force
      ;;
  esac
}