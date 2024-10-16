#!/bin/zsh

function brew() {
  local cmd=$1
  local args="${@:2}"

  local DEFAULT_BREWFILE="~/.Brewfile"
  local DUMP_COMMANDS=(
    install
    uninstall
    remove
    reinstall
    upgrade
    cleanup
    link
    unlink
    pin
    unpin
    tap
    untap
  )

  [[ -z "$BREWFILE" ]] && export BREWFILE="$DEFAULT_BREWFILE"
  
  case $cmd in
    dump)
      command brew bundle dump --file="$BREWFILE" --brews --casks --taps --mas --describe --force --cleanup --no-restart $args
      ;;
    fresh)
      command brew update && 
      command brew upgrade &&
      command brew cleanup &&
      brew dump &&
      command brew doctor
      ;;
    global)
      command brew bundle --file="$BREWFILE" $args
      ;;
    reset)
      command brew update-reset $args
      ;;
    *)
      command brew $@
      local exit_code=$?

      if [[ " ${DUMP_COMMANDS[@]} " =~ " $cmd " ]] && [[ $exit_code == 0 ]] && [[ ! $2 =~ "^(-h|--help)$" ]]; then
        ((brew dump && brew global) &>/dev/null &) &>/dev/null
      fi

      return $exit_code
  esac
}

function mas() {
  local cmd=$1

  local DUMP_COMMANDS=(
    install
    uninstall
    upgrade
  )

  sudo command mas $@
  local exit_code=$?

  if [[ " ${DUMP_COMMANDS[@]} " =~ " $cmd " ]] && [[ $exit_code == 0 ]]; then
    ((brew dump && brew global) >/dev/null &) >/dev/null
  fi

  return $exit_code
}
