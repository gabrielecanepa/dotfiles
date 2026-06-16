# Re-assert machine-local dotfiles state that drifts over time, such as git config the repo does not persist and symlinks that apps clobber on update.
#
# Usage: dotfiles <command>

# Whether the repo-local git hooks path points at the tracked hooks.
_dotfiles_hooks_ok() {
  emulate -L zsh
  [[ "$(command git -C "$HOME" config --local --get core.hooksPath 2>/dev/null)" == ".config/git/hooks" ]]
}

# Whether the live VS Code settings file ($1) is the tracked file ($2, same inode).
# Non-Darwin and a missing live file both count as "nothing to repair".
_dotfiles_vscode_ok() {
  emulate -L zsh
  local live="$1" tracked="$2"
  [[ $OSTYPE != darwin* ]] && return 0
  [[ ! -e "$live" ]] && return 0
  # -ef is true when both paths resolve to the same inode (the symlink is intact).
  [[ "$live" -ef "$tracked" ]]
}

# Self-heal machine-local dotfiles state.
dotfiles() {
  emulate -L zsh

  local info="${fg[blue]}info${reset_color}"
  local error="${fg[red]}error${reset_color}"
  local success="${fg[green]}success${reset_color}"
  local warn="${fg[yellow]}warn${reset_color}"

  local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
  local vscode_tracked="$HOME/.vscode/user/settings.json"

  case "$1" in
    init|"")
      integer rc=0 verbose=0
      [[ "$2" == (-v|--verbose) ]] && verbose=1

      if _dotfiles_hooks_ok; then
        (( verbose )) && print -r -- "$info git hooks path already set 🪝"
      elif command git -C "$HOME" config --local core.hooksPath .config/git/hooks; then
        (( verbose )) && print -r -- "$success git hooks path set to .config/git/hooks 🪝"
      else
        print -ru2 -- "$error failed to set git hooks path"
        rc=1
      fi

      if [[ $OSTYPE != darwin* ]]; then
        return rc
      elif _dotfiles_vscode_ok "$vscode_settings" "$vscode_tracked"; then
        (( verbose )) && print -r -- "$info VS Code settings symlink intact 🔗"
      elif [[ ! -e "$vscode_tracked" ]]; then
        # Nothing to link to; warn instead of creating a dangling symlink.
        print -ru2 -- "$warn tracked VS Code settings missing at $vscode_tracked"
      elif command ln -sf "$vscode_tracked" "$vscode_settings"; then
        (( verbose )) && print -r -- "$success VS Code settings re-linked 🔗"
      else
        print -ru2 -- "$error failed to re-link VS Code settings"
        rc=1
      fi

      return rc
      ;;
    doctor)
      integer drift=0
      if _dotfiles_hooks_ok; then
        print -r -- "$success git hooks path OK"
      else
        print -r -- "$error git hooks path NOT set to .config/git/hooks"
        drift=1
      fi
      if [[ $OSTYPE == darwin* ]]; then
        if _dotfiles_vscode_ok "$vscode_settings" "$vscode_tracked"; then
          print -r -- "$success VS Code settings symlink OK"
        else
          print -r -- "$error VS Code settings is not a symlink to the tracked file"
          drift=1
        fi
      fi
      (( drift == 0 )) && print -r -- "$info no drift detected ✨"
      return drift
      ;;
    help|-h|--help)
      print -r -- "Usage: dotfiles <command>"
      print -r --
      print -r -- "Commands:"
      print -r -- "    init [-v|--verbose]   Fix any drifted state, silently unless verbose (default; idempotent)."
      print -r -- "    doctor                Report drift without changing anything."
      print -r -- "    help                  Show this message."
      ;;
    *)
      print -r -- "$error Unknown command: $1"
      print -r --
      dotfiles --help
      return 1
      ;;
  esac
}
