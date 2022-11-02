#!/bin/zsh
# requires $UP_TO_DATE to be set

function up-to-date() {
  {
    function current_epoch() {
      zmodload zsh/datetime
      echo $(( EPOCHSECONDS / 60 / 60 / 24 ))
    }

    function upgrade_plugins() {
      echo ""
      echo "${fg[blue]}[plugins] info${reset_color} Upgrading Oh My Zsh plugins"
      for plugin in $ZSH_CUSTOM/plugins/*; do
        if [[ -d $plugin/.git ]]; then
          cd $plugin
          git fetch --all
          if [[ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]]; then
            git pull --rebase &>/dev/null
          fi
          echo "${fg[blue]}[plugins] success${reset_color} $plugin:t upgraded"
          cd - &>/dev/null
        fi
      done
    }

    function upgrade_brew() {
      brew fresh
      echo "${fg[green]}success${reset_color} Homebrew packages upgraded"
    }

    function upgrade_yarn() {
      echo ""
      echo "${fg[blue]}info${reset_color} Upgrading global Yarn packages"
      yarn global upgrade
      echo "\n${fg[green]}success${reset_color} Yarn packages upgraded"
    }

    function upgrade_all() {
      if [[ -z $UP_TO_DATE ]]; then
        echo "\n${fg[red]}error${reset_color} \$UP_TO_DATE hasn't been specified"
        return 1
      fi

      for include in $UP_TO_DATE; do
        if ! upgrade_$include; then
          echo "\n\${fg[red]}error${reset_color} $include:t upgrade failed"
        fi
      done

      unset $include
    }

    . "${ZSH_CACHE_DIR}/.zsh-update" # loads LAST_EPOCH

    if [[ $1 = "init" ]] && [[ $(($(current_epoch) - $LAST_EPOCH)) > $UPDATE_ZSH_DAYS ]]; then
      return
    fi

    if [[ -z $DISABLE_AUTO_UPDATE ]] || [[ $DISABLE_AUTO_UPDATE = "false" ]]; then
      upgrade_all
      return $?
    fi

    printf "\n[up-to-date] Would you like to upgrade? [Y/n] "
    read -r -k 1 option

    case "$option" in
      [yY$'\n']) upgrade_all;;
      *) echo "\n[up-to-date] You can upgrade manually by running ${fg[green]}up-to-date${reset_color}\n";;
    esac

    unset option
    unset -f current_epoch upgrade_plugins upgrade_brew upgrade_yarn upgrade_all
  } 2>/dev/null
}

up-to-date init
