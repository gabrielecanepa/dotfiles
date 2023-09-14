#!/bin/zsh

function gatekeeper() {
  local INFO="${fg[blue]}info${reset_color}"
  local ERROR="${fg[red]}error${reset_color}"
  local SUCCESS="${fg[green]}success${reset_color}"
  local WARN="${fg[yellow]}warn${reset_color}"

  case $1 in
    status)
      if sudo spctl --status >/dev/null 2>&1; then
        echo "$INFO GateKeeper is enabled globally 🔒"
        return 0
      fi

      echo "$WARN GateKeeper is currently disabled 🔓"
      printf "Do you want to enable it? (Y/n) "
      read -r choice
      if [[ -z "$choice" ]] || [[ "$choice" =~ [yY] ]]; then
        gatekeeper enable
      fi
      ;;
    disable)
      if ! sudo spctl --status >/dev/null 2>&1; then
        echo "$INFO GateKeeper is already disabled 🔓"
        return 0
      fi

      case $2 in
        "")
          echo "$WARN This will disable GateKeeper globally"
          printf "Are you sure you want to continue? (y/N) "
          read -r choice
          
          if [[ "$choice" =~ [yY] ]]; then
            if ! sudo spctl --master-disable >/dev/null 2>&1; then
              echo "$ERROR An issue occured, please check the logs"
              return 1
            fi

            echo "$SUCCESS GateKeeper disabled globally 🔓"
          fi
          ;;
        -a)
          local apps=(${@:3})

          if [[ ${#apps[@]} == 0 ]]; then
            echo "$ERROR No applications provided"
            return 1
          fi

          for app in ${apps[@]}; do
            local app_path="/Applications/$app.app"

            if [[ ! -d "$app_path" ]]; then
              echo "$ERROR $app is not installed"
              return 1
            fi

            if ! sudo xattr -r -d com.apple.quarantine "$app_path" 2>/dev/null; then
              echo "$ERROR Can't disable GateKeeper for $app"
              return 1
            fi

            echo "${fg[green]}success$reset_color GateKeeper disabled on $app 🔓"
          done
          ;;
        *)
          for resource in ${@:2}; do
            if ! sudo xattr -r -d com.apple.quarantine "$resource" 2>/dev/null; then
              echo "$ERROR Can't disable GateKeeper on ${resource##*/}"
              return 1
            fi
            
            echo "$SUCCESS GateKeeper disabled on ${resource##*/} 🔓"
          done
          ;;
      esac
      ;;
    enable)
      if sudo spctl --status >/dev/null 2>&1; then
        echo "$INFO GateKeeper is already enabled 🔒"
        return 0
      fi

      if sudo spctl --master-enable >/dev/null 2>&1; then
        echo "$SUCCESS GateKeeper enabled globally 🔒"
        return 0
      fi

      echo "$ERROR An issue occured, please try again"
      ;;
    help|-h|--help)
      echo "Usage: gatekeeper <command>"
      echo ""
      echo "Commands:"
      echo -e "  status \t\t Print the current status"
      echo -e "  disable [resources] \t Disable GateKeeper on the specified resources, or globally if no arguments are provided"
      echo -e "  disable -a [apps] \t Disable GateKeeper on the specified applications"
      echo -e "  enable \t\t Enable GateKeeper globally"
      echo -e "  help \t\t\t Show this help message"
      ;;
    *)
      if [[ -n "$1" ]]; then
        echo "$ERROR Unknown command: $1"
        echo ""
      fi
      gatekeeper --help
      ;;
  esac
}
