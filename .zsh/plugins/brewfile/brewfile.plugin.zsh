#!/bin/zsh

brew() {
  case $1 in
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
    dump)
      command brew bundle dump ${@:2} --global --describe
      ;;
    install|uninstall)
      command brew $1 ${@:2} && brew dump --force
      ;;
    *)
      command brew $@
  esac
}
