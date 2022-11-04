#!/bin/zsh

function up-to-date() {
  args="$([[ $1 = "--init" ]] && echo "$@:2" || echo "$@")"

  {
    function current_epoch() {
      zmodload zsh/datetime
      echo $(( EPOCHSECONDS / 60 / 60 / 24 ))
    }

    function upgrade_plugins() {
      echo ""
      echo "[up-to-date] ${fg[blue]}info${reset_color} Upgrading Oh My Zsh plugins"
      for plugin in $ZSH_CUSTOM/plugins/*; do
        if [[ -d $plugin/.git ]]; then
          cd $plugin
          git fetch --all
          if [[ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]]; then
            git pull --rebase &>/dev/null
            echo "\n${fg[blue]}success${reset_color} $plugin:t upgraded"
            has_plugins=1
          fi
        fi
      done
      if [[ -z $has_plugins ]]; then
        echo "${fg[blue]}info${reset_color} No plugins to upgrade"
      fi
      cd - &>/dev/null
    }

    function upgrade_brew() {
      echo ""
      echo "${fg[blue]}info${reset_color} Upgrading Homebrew packages"
      brew update && brew upgrade
      echo "\n${fg[blue]}info${reset_color} Cleaning up old brew packages"
      [[ -z "$(brew cleanup)" ]] && echo "No packages to cleanup"
      echo "\n${fg[blue]}info${reset_color} Running brew doctor"
      [[ -z "$(brew doctor)" ]] && echo "No issues found"
      echo "\n${fg[green]}success${reset_color} Homebrew packages upgraded"
    }

    function upgrade_yarn() {
      echo ""
      echo "${fg[blue]}info${reset_color} Upgrading Yarn packages"
      yarn global upgrade
      echo "\n${fg[green]}success${reset_color} Yarn packages upgraded"
    }

    function upgrade_all() {
      if [[ -z "$args" ]] && [[ -z "$UPDATE_ZSH_EXTEND" ]]; then
        echo "\n${fg[red]}error${reset_color} You must provide at least one option"
        return 1
      fi

      extensions=($([[ -z "$args" ]] && echo "$UPDATE_ZSH_EXTEND" || echo "$args"))

      for extension in $(echo $extensions); do
        if ! type -a upgrade_$extension >/dev/null; then
          echo ""
          echo "${fg[red]}error${reset_color} $extension is not a valid option"
        fi
        if ! upgrade_$extension; then
          echo ""
          echo "${fg[red]}error${reset_color} $extension:t upgrade failed"
        fi
      done

      unset extensions extension
    }

    . "${ZSH_CACHE_DIR}/.zsh-update" # loads LAST_EPOCH

    if [[ $1 = "--init" ]] && [[ $(($(current_epoch) - $LAST_EPOCH)) > $UPDATE_ZSH_DAYS ]]; then
      return
    fi

    if [[ -z $DISABLE_AUTO_UPDATE ]] || [[ $DISABLE_AUTO_UPDATE = "false" ]]; then
      upgrade_all
      return $?
    fi

    printf "[up-to-date] Would you like to upgrade? [Y/n] "
    read -r -k 1 option

    case "$option" in
      [yY$'\n'])
        echo "[up-to-date] The process might take a while"
        printf "[up-to-date] Would you like to open a new terminal tab? [Y/n] "
        read -r -k 1 new_tab
        if [[ $new_tab = [yY$'\n'] ]]; then
          # TODO: open new tab
        fi
        unset new_tab

        upgrade_all $args
        ;;
      *)
        echo "\r\n[up-to-date] You can upgrade manually by running ${fg[green]}up-to-date${reset_color}\n"
        ;;
    esac

    unset option
    unset -f current_epoch upgrade_plugins upgrade_brew upgrade_yarn upgrade_all
  } 2>/dev/null

  unset args
}

up-to-date --init
