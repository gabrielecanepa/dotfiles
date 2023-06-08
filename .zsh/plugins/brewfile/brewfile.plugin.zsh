#!/bin/zsh

function brew() {
  case "$1" in
    dump)
      command brew bundle dump --global --force --describe --cleanup
      ;;
    fresh)
      command brew update && 
      command brew bundle --global &&
      command brew cleanup && 
      command brew doctor
      ;;
    install|uninstall|upgrade|tap|untap)
      command brew $@
      if [[ $? == 0 ]] && [[ ! $2 =~ "^(-h|--help)$" ]]; then
        brew dump
      fi
      ;;
    *)
      command brew $@
      ;;
  esac
}
