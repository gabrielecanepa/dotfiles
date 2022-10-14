#!/bin/sh

brew() {
  case $1 in
    dump)
      command brew bundle dump --global --brews --casks --taps --force --describe --cleanup --no-lock
      ;;
    fresh)
      echo "${fg[blue]}info${reset_color} Updating existing packages"
      brew update && brew upgrade
      echo "\n${fg[blue]}info${reset_color} Cleaning up old packages"
      [[ -z "$(brew cleanup)" ]] && echo "No packages to cleanup."
      echo "\n${fg[blue]}info${reset_color} Running brew doctor"
      brew doctor
      ;;
    init)
      if [[ -f "${HOME}/.Brewfile" ]]; then
        printf "${fg[yellow]}warning${reset_color} A Brewfile already exists. Do you want to override it? [y/N] "
        read -r choice
        case "$choice" in
          y|Y)
            rm -f "$brewfile_path" "${brewfile_path}.lock.json"
            brew dump
            ;;
          n|N|"")
            ;;
          *)
            echo "${fg[red]}error${reset_color} Unknown option: $choice"
            unset choice
            return 1
            ;;
        esac
        unset choice
      else
        brew dump
      fi
      command brew bundle install --global
      ;;
    install)
      command brew $@
      printf "${fg[blue]}==>${reset_color} Updating Brewfile..."
      brew dump &>/dev/null
      echo "\r"
      ;;
    uninstall)
      command brew $@
      echo "Updating Brewfile..."
      brew dump &>/dev/null
      ;;
    *)
      command brew $@
      ;;
  esac
}
