#!/bin/zsh

function brew() {
  case "$1" in
    install|uninstall|upgrade|tap|untap)
      if command brew $@; then
        printf "${fg[blue]}==>${reset_color} Updating Brewfile"
        command brew bundle dump --global --force --describe --cleanup
        echo "\r"
      fi
      ;;
    *)
      command brew $@
      ;;
  esac
}
