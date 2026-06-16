# Toggle macOS GateKeeper globally or strip the quarantine attribute from specific apps/resources.
#
# Usage: gatekeeper <command>

gatekeeper() {
  emulate -L zsh

  local info="${fg[blue]:-}info${reset_color:-}"
  local error="${fg[red]:-}error${reset_color:-}"
  local success="${fg[green]:-}success${reset_color:-}"
  local warn="${fg[yellow]:-}warn${reset_color:-}"

  case $1 in
    status)
      if command sudo spctl --status >/dev/null 2>&1; then
        print -r -- "$info GateKeeper is enabled globally 🔒"
        return 0
      fi

      print -r -- "$warn GateKeeper is currently disabled 🔓"
      printf 'Do you want to enable it? (Y/n) '
      local choice
      read -r choice
      if [[ -z "$choice" || "$choice" == [yY]* ]]; then
        gatekeeper enable
        return $?
      fi
      return 0
      ;;
    disable)
      if ! command sudo spctl --status >/dev/null 2>&1; then
        print -r -- "$info GateKeeper is already disabled 🔓"
        return 0
      fi

      case $2 in
        "")
          print -r -- "$warn This will disable GateKeeper globally" >&2
          printf 'Are you sure you want to continue? (y/N) '
          local choice
          read -r choice

          if [[ "$choice" == [yY]* ]]; then
            if ! command sudo spctl --master-disable >/dev/null 2>&1; then
              print -r -- "$error An issue occurred, please check the logs" >&2
              return 1
            fi

            print -r -- "$success GateKeeper disabled globally 🔓"
            return 0
          fi
          return 0
          ;;
        -a)
          local -a apps=("${@:3}")

          if (( $#apps == 0 )); then
            print -r -- "$error No applications provided" >&2
            return 1
          fi

          local app app_path
          for app in "${apps[@]}"; do
            app_path="/Applications/$app.app"

            if [[ ! -d "$app_path" ]]; then
              print -r -- "$error $app is not installed" >&2
              return 1
            fi

            # Strip the quarantine flag so GateKeeper stops blocking it
            if ! command sudo xattr -r -d com.apple.quarantine "$app_path" 2>/dev/null; then
              print -r -- "$error Can't disable GateKeeper for $app" >&2
              return 1
            fi

            print -r -- "$success GateKeeper disabled on $app 🔓"
          done
          return 0
          ;;
        *)
          local resource
          for resource in "${@:2}"; do
            if ! command sudo xattr -r -d com.apple.quarantine "$resource" 2>/dev/null; then
              # ${resource##*/} is the basename
              print -r -- "$error Can't disable GateKeeper on ${resource##*/}" >&2
              return 1
            fi

            print -r -- "$success GateKeeper disabled on ${resource##*/} 🔓"
          done
          return 0
          ;;
      esac
      ;;
    enable)
      if command sudo spctl --status >/dev/null 2>&1; then
        print -r -- "$info GateKeeper is already enabled 🔒"
        return 0
      fi

      if command sudo spctl --master-enable >/dev/null 2>&1; then
        print -r -- "$success GateKeeper enabled globally 🔒"
        return 0
      fi

      print -r -- "$error An issue occurred, please try again" >&2
      return 1
      ;;
    help|-h|--help)
      print -r -- "Usage: gatekeeper <command>"
      print -r --
      print -r -- "Commands:"
      print -r -- "    status               Print the current status."
      print -r -- "    enable               Enable GateKeeper globally."
      print -r -- "    disable [resources]  Disable GateKeeper globally, or strip quarantine from the given paths."
      print -r -- "    disable -a [apps]    Strip quarantine from the named /Applications bundles."
      print -r -- "    help                 Show this message."
      return 0
      ;;
    *)
      if [[ -n "$1" ]]; then
        print -r -- "$error Unknown command: $1" >&2
        print -- "" >&2
        gatekeeper --help >&2
        return 1
      fi
      gatekeeper --help
      return 0
      ;;
  esac
}
