#!/bin/zsh

function brew() {
  local log_default="[$plugin_name]"
  local log_info="[$plugin_name] ${fg[blue]}info${reset_color}"
  local log_warning="[$plugin_name] ${fg[yellow]}warning${reset_color}"
  local log_error="[$plugin_name] ${fg[red]}error${reset_color}"
  local log_success="[$plugin_name] ${fg[green]}success${reset_color}"

  case $1 in
    dump)
      command brew bundle dump --global --brews --casks --taps --force --describe --cleanup --no-lock
      ;;
    fresh)
      echo "$log_info Upgrading brew packages"
      brew update && brew upgrade
      echo "\n$log_info Cleaning up old packages"
      [[ -z "$(brew cleanup)" ]] && echo "No packages to cleanup"
      echo "\n$log_info Running brew doctor"
      brew doctor
      ;;
    init)
      if [[ -f "${HOME}/.Brewfile" ]]; then
        printf "$log_warning A Brewfile already exists. Do you want to override it? [y/N] "
        read -r -k 1 choice
        case "$choice" in
          [yY])
            rm -f "$brewfile_path" "${brewfile_path}.lock.json"
            brew dump
            ;;
          [nN$'\n'])
            ;;
          *)
            echo "$log_error Unknown option: $choice"
            unset choice
            return 1
            ;;
        esac
        unset choice
      else
        brew dump
      fi
      brew install-global
      ;;
    install)
      command brew $@
      printf "${fg[blue]}==>${reset_color} Updating Brewfile"
      brew dump &>/dev/null
      echo "\r"
      ;;
    install-global)
      command brew bundle install --global
      ;;
    uninstall)
      command brew $@
      echo "Updating Brewfile"
      brew dump &>/dev/null
      ;;
    *)
      command brew $@
      ;;
  esac
}
