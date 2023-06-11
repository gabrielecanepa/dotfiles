#!/bin/zsh

function brew() {
  case "$1" in
    dump)
      command brew bundle dump --global --force --all --describe --cleanup --no-restart
      ;;
    fresh)
      command brew update && 
      command brew bundle --global &&
      command brew bundle cleanup --global &&
      command brew cleanup && 
      command brew doctor
      ;;
    reset)
      command brew update-reset
      ;;
    install|uninstall|reinstall|upgrade|tap|untap)
      command brew $@
      local exit_code=$?

      if [[ $? == 0 ]] && [[ ! $2 =~ "^(-h|--help)$" ]]; then
        brew dump
      fi

      return $exit_code
      ;;
    *)
      command brew $@
      ;;
  esac
}
