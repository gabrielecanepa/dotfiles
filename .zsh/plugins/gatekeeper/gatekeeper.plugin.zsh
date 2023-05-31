#!/bin/zsh

function gatekeeper() {
  case $1 in
    status)
      if (sudo spctl --status >/dev/null 2>&1); then
        echo "🔒 GateKeeper is enabled globally"
      else
        echo "${fg[yellow]}🔓 GateKeeper is currently disabled$reset_color"
        printf "Do you want to enable it? (Y/n) "
        read -r choice
        if [[ -z "$choice" ]] || [[ "$choice" =~ [yY] ]]; then
          gatekeeper enable
        fi
      fi
      ;;
    disable)
      if (! sudo spctl --status >/dev/null 2>&1); then
        echo "GateKeeper is already disabled"
      elif [ -z $2 ]; then
        echo "${fg[yellow]}WARNING: this will disable GateKeeper globally$reset_color"
        printf "Are you sure you want to continue? (y/N) "
        read -r choice
        if [[ "$choice" =~ [yY] ]]; then
          if (sudo spctl --master-disable >/dev/null 2>&1); then
            echo "🔓 GateKeeper disabled globally"
          else
            echo "${fg[red]}Error: an issue occured, please try again$reset_color"
          fi
        fi
      else
        for app in "${@:2}"; do
          if (sudo xattr -r -d com.apple.quarantine "$app" 2>/dev/null); then
            echo "🔓 GateKeeper disabled for ${app##*/}"
          else
            echo "${fg[red]}Can't disable GateKeeper for ${app##*/}$reset_color"
          fi
        done
      fi
      ;;
    enable)
      if (sudo spctl --status >/dev/null 2>&1); then
        echo "GateKeeper is already enabled"
      elif (sudo spctl --master-enable >/dev/null 2>&1); then
        echo "🔒 GateKeeper enabled globally"
      else
        echo "${fg[red]}Error: an issue occured, please try again$reset_color"
      fi
      ;;
    help|-h|--help)
      echo "Usage: gatekeeper <command>"
      echo ""
      echo "Commands:"
      echo -e "  status \t\t Print the current status"
      echo -e "  disable [apps] \t Disable checks for the specified apps, or globally if no arguments are provided"
      echo -e "  enable \t\t Enable checks globally"
      ;;
    *)
      if [[ -n "$1" ]]; then
        echo "${fg[red]}Unknown command: $1$reset_color"
        echo ""
      fi
      gatekeeper --help
      ;;
  esac
}
