#!/bin/sh

function uptodate() {
  local plugin_name="uptodate"
  local args="$([[ $1 = "--init" ]] && echo "${@:2}" || echo "$@")"
  local extensions=($([[ -z "$args" ]] && echo "$UPDATE_ZSH_EXTEND" || echo "$args"))

  if [[ -z "$extensions" ]]; then
    return $?
  fi

  local log_default="[$plugin_name]"
  local log_info="[$plugin_name] ${fg[blue]}info${reset_color}"
  local log_warning="[$plugin_name] ${fg[yellow]}warning${reset_color}"
  local log_error="[$plugin_name] ${fg[red]}error${reset_color}"
  local log_success="[$plugin_name] ${fg[green]}success${reset_color}"

  {
    local function current_epoch() {
      zmodload zsh/datetime
      echo $(( EPOCHSECONDS / 60 / 60 / 24 ))
    }

    local function upgrade_plugins() {
      echo "$log_info Upgrading Oh My Zsh plugins"
      for plugin in $ZSH_CUSTOM/plugins/*; do
        if [[ -d $plugin/.git ]]; then
          cd $plugin
          git fetch --all
          if [[ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]]; then
            git pull --rebase &>/dev/null
            echo "$log_success $plugin:t upgraded"
            has_plugins=1
          fi
        fi
      done
      if [[ -z $has_plugins ]]; then
        echo "$log_info No plugins to upgrade"
      fi
      cd - &>/dev/null
    }

    local function upgrade_brew() {
      echo "$log_info Upgrading Homebrew packages"
      brew update && brew upgrade
      echo "$log_info Cleaning up old brew packages"
      [[ -z "$(brew cleanup)" ]] && echo "No packages to cleanup."
      echo "$log_info Running brew doctor"
      [[ -z "$(brew doctor)" ]] && echo "No issues found."
      echo "$log_success Homebrew packages upgraded"
    }

    local function upgrade_yarn() {
      echo "$log_info Upgrading Yarn packages"
      yarn global upgrade
      echo "$log_success Yarn packages upgraded"
    }

    local function upgrade_all() {
      for extension in $(echo $extensions); do
        if ! type -a upgrade_$extension >/dev/null; then
          echo "$log_error $extension is not a valid option"
        fi
        if ! upgrade_$extension; then
          echo "$log_error $extension:t upgrade failed"
        fi
      done
      unset extension
    }

    . "${ZSH_CACHE_DIR}/.zsh-update" # load LAST_EPOCH

    if [[ $1 = "--init" ]] && [[ $(($(current_epoch) - $LAST_EPOCH)) > $UPDATE_ZSH_DAYS ]]; then
      return
    fi

    if [[ -z $DISABLE_AUTO_UPDATE ]] || [[ $DISABLE_AUTO_UPDATE = "false" ]]; then
      upgrade_all
      return $?
    fi

    printf "$log_default Would you like to upgrade? [Y/n] "
    read -r -k 1 option

    case "$option" in
      [yY$'\n'])
        # TODO: update last upgrade date
        echo "$log_warning The process might take a while"
        printf "$log_default Would you like to open a new terminal tab? [Y/n] "
        read -r -k 1 new_tab
        if [[ $new_tab = [yY$'\n'] ]]; then
          # Visual Studio Code
          osascript -e '
            tell application "System Events" to tell process "Code"
              click menu item "New Terminal" of menu 1 of menu bar item "Terminal" of menu bar 1
            end tell
          ' &>/dev/null
        fi
        unset new_tab

        upgrade_all $args
        ;;
      *)
        echo "\r\n$log_default You can upgrade manually by running ${fg[green]}uptodate${reset_color}"
        ;;
    esac

    unset option
  } 2>/dev/null
}

uptodate --init
