(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

gatekeeper() {
  emulate -L zsh

  case $1 in
    status)
      if command sudo spctl --status >/dev/null 2>&1; then
        _zsh::log info gatekeeper 'GateKeeper is enabled globally 🔒'
        return 0
      fi

      _zsh::log warn gatekeeper 'GateKeeper is currently disabled 🔓'
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
        _zsh::log info gatekeeper 'GateKeeper is already disabled 🔓'
        return 0
      fi

      case $2 in
        "")
          _zsh::log warn gatekeeper 'this will disable GateKeeper globally'
          printf 'Are you sure you want to continue? (y/N) '
          local choice
          read -r choice

          if [[ "$choice" == [yY]* ]]; then
            if ! command sudo spctl --global-disable >/dev/null 2>&1; then
              _zsh::log error gatekeeper 'an issue occurred, please check the logs'
              return 1
            fi

            _zsh::log success gatekeeper 'GateKeeper disabled globally 🔓'
            return 0
          fi
          return 0
          ;;
        -a)
          local -a apps=("${@:3}")

          if (( $#apps == 0 )); then
            _zsh::log error gatekeeper 'no applications provided'
            return 1
          fi

          local app app_path
          for app in "${apps[@]}"; do
            app_path="/Applications/$app.app"

            if [[ ! -d "$app_path" ]]; then
              _zsh::log error gatekeeper "$app is not installed"
              return 1
            fi

            if ! command sudo xattr -r -d com.apple.quarantine "$app_path" 2>/dev/null; then
              _zsh::log error gatekeeper "can't disable GateKeeper for $app"
              return 1
            fi

            _zsh::log success gatekeeper "GateKeeper disabled on $app 🔓"
          done
          return 0
          ;;
        *)
          local resource
          for resource in "${@:2}"; do
            if ! command sudo xattr -r -d com.apple.quarantine "$resource" 2>/dev/null; then
              _zsh::log error gatekeeper "can't disable GateKeeper on ${resource:t}"
              return 1
            fi

            _zsh::log success gatekeeper "GateKeeper disabled on ${resource:t} 🔓"
          done
          return 0
          ;;
      esac
      ;;
    enable)
      if command sudo spctl --status >/dev/null 2>&1; then
        _zsh::log info gatekeeper 'GateKeeper is already enabled 🔒'
        return 0
      fi

      _zsh::log warn gatekeeper 're-enabling GateKeeper globally is no longer possible from the CLI on macOS 15+'
      _zsh::log info gatekeeper 'enable it in System Settings > Privacy & Security > Security'
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
        _zsh::log error gatekeeper "unknown command: $1"
        print -ru2 -- ''
        gatekeeper --help >&2
        return 1
      fi
      gatekeeper --help
      return 0
      ;;
  esac
}
