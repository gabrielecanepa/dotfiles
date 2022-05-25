#!/bin/zsh

brew() {
  case $1 in
    dump)
      command brew bundle dump ${@:2} --global --brews --taps --casks --describe --cleanup 
      ;;
    fresh)
      echo "${fg[blue]}info${reset_color} Updating existing packages"
      brew update
      brew upgrade
      echo "${fg[blue]}info${reset_color} Cleaning up old packages"
      brew cleanup
      echo "${fg[blue]}info${reset_color} Checking for errors"
      brew doctor
      echo "${fg[blue]}info${reset_color} Updating Yarn packages"
      yarn global upgrade
      ;;
    init)
      if [  -f "$HOME/.Brewfile" ]; then
        printf "${fg[yellow]}warning${reset_color} A Brewfile already exists. Do you want to override it? [y/N] "
        read -r choice
        case "$choice" in
          y|Y)
            rm -f "$HOME/.Brewfile" "$HOME/.Brewfile.lock.json"
            brew dump
            ;;
          n|N|"")
            ;;
          *)
            echo "${fg[red]}error${reset_color} Unknown option: $choice"
            unset $choice
            return 1
            ;;
        esac
        unset $choice
      else
        brew dump
      fi
      command brew bundle install --global
      ;;
    *)
      command brew $@ && brew dump --force
      ;;
  esac
}
