#!/bin/zsh

function brew() {
  local function dump_brewfile() {
    printf "${fg[blue]}==>${reset_color} Updating Brewfile"
    brew dump
    echo "\r"
  }

  case $1 in
    dump)
      command brew bundle dump --global --force --describe --cleanup
      ;;
    init)
      if [[ -f "$HOMEBREW_BUNDLE_FILE" ]]; then
        printf "${fg[yellow]}A Brewfile already exists. Do you want to override it with your current configuration? [y/N]$reset_color "
        read -r -k 1 choice
        case "$choice" in
          [yY])
            rm -f "$HOMEBREW_BUNDLE_FILE" "${HOMEBREW_BUNDLE_FILE}.lock.json"
            brew dump
            ;;
          [nN$'\n'])
            ;;
          *)
            echo "${fg[red]}Unknown option: $choice$reset_color"
            unset choice
            return 1
            ;;
        esac
        unset choice
      else
        brew dump
      fi
      brew install --global
      ;;
    install)
      if [[ $2 = "--global" ]]; then
        command brew bundle install --global
        return $?
      fi
      command brew $@
      dump_brewfile
      ;;
    uninstall)
      command brew $@
      dump_brewfile
      ;;
    *)
      command brew $@
      ;;
  esac
}
