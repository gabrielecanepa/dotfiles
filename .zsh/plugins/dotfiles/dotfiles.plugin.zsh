#
# dotfiles: re-assert machine-local state that drifts, like git config and clobbered symlinks.
# Usage: dotfiles <init|doctor|help>

(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

_dotfiles_encoding_ok() {
  emulate -L zsh
  [[ -e "$HOME/.CFUserTextEncoding" ]]
}

_dotfiles_hushlogin_ok() {
  emulate -L zsh
  [[ -e "$HOME/.hushlogin" ]]
}

_dotfiles_git_hooks_ok() {
  emulate -L zsh
  [[ "$(command git -C "$HOME" config --local --get core.hooksPath 2>/dev/null)" == ".config/git/hooks" ]]
}

_dotfiles_vscode_ok() {
  emulate -L zsh
  local live="$1" tracked="$2"
  [[ $OSTYPE != darwin* ]] && return 0
  [[ ! -e "$live" ]] && return 0
  [[ "$live" -ef "$tracked" ]]
}

_dotfiles_vscode_extensions() {
  emulate -L zsh
  local file="$HOME/.vscode/extensions.json" dir="$HOME/.vscode/extensions"
  [[ -f "$file" ]] || return 0
  local -a ids hits
  ids=(${(f)"$(command grep -oE '"[A-Za-z0-9-]+\.[A-Za-z0-9._-]+"' "$file")"})
  ids=(${(L)ids//\"/})
  local id
  for id in $ids; do
    hits=("$dir"/"$id"-*(N/))
    (( $#hits )) || print -r -- "$id"
  done
  return 0
}

dotfiles() {
  emulate -L zsh

  local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
  local vscode_tracked="$HOME/.vscode/user/settings.json"

  case "$1" in
    init|"")
      integer rc=0 verbose=0
      [[ "$2" == (-v|--verbose) ]] && verbose=1

      if _dotfiles_git_hooks_ok; then
        (( verbose )) && _zsh::log info dotfiles "git hooks path already set 🪝"
      elif command git -C "$HOME" config --local core.hooksPath .config/git/hooks; then
        (( verbose )) && _zsh::log success dotfiles "git hooks path set to .config/git/hooks 🪝"
      else
        _zsh::log error dotfiles "failed to set git hooks path"
        rc=1
      fi

      if _dotfiles_hushlogin_ok; then
        (( verbose )) && _zsh::log info dotfiles "login banner already silenced 🤫"
      elif command touch "$HOME/.hushlogin"; then
        (( verbose )) && _zsh::log success dotfiles "login banner silenced via ~/.hushlogin 🤫"
      else
        _zsh::log error dotfiles "failed to create ~/.hushlogin"
        rc=1
      fi

      if [[ $OSTYPE == darwin* ]]; then
        if _dotfiles_encoding_ok; then
          (( verbose )) && _zsh::log info dotfiles "user text encoding already pinned 🔤"
        elif print -r -- '0x0:0x0' > "$HOME/.CFUserTextEncoding"; then
          (( verbose )) && _zsh::log success dotfiles "user text encoding pinned via ~/.CFUserTextEncoding 🔤"
        else
          _zsh::log error dotfiles "failed to create ~/.CFUserTextEncoding"
          rc=1
        fi
      fi

      if [[ $OSTYPE != darwin* ]]; then
        return rc
      elif _dotfiles_vscode_ok "$vscode_settings" "$vscode_tracked"; then
        (( verbose )) && _zsh::log info dotfiles "VS Code settings symlink intact 🔗"
      elif [[ ! -e "$vscode_tracked" ]]; then
        _zsh::log warn dotfiles "tracked VS Code settings missing at $vscode_tracked"
      elif command ln -sf "$vscode_tracked" "$vscode_settings"; then
        (( verbose )) && _zsh::log success dotfiles "VS Code settings re-linked 🔗"
      else
        _zsh::log error dotfiles "failed to re-link VS Code settings"
        rc=1
      fi

      local -a extensions
      extensions=(${(f)"$(_dotfiles_vscode_extensions)"})
      if (( $#extensions == 0 )); then
        (( verbose )) && _zsh::log info dotfiles "VS Code extensions in sync 🧩"
      elif ! (( $+commands[code] )); then
        _zsh::log warn dotfiles "code CLI not found, skipping $#extensions missing extension(s)"
      else
        local extension
        for extension in $extensions; do
          if command code --install-extension "$extension" >/dev/null 2>&1; then
            _zsh::log success dotfiles "VS Code extension $extension installed 🧩"
          else
            _zsh::log warn dotfiles "failed to install VS Code extension $extension"
          fi
        done
      fi

      return rc
      ;;
    doctor)
      integer drift=0
      if _dotfiles_git_hooks_ok; then
        _zsh::log success dotfiles "git hooks path OK"
      else
        _zsh::log error dotfiles "git hooks path is NOT .config/git/hooks"
        drift=1
      fi
      if _dotfiles_hushlogin_ok; then
        _zsh::log success dotfiles "hushlogin OK"
      else
        _zsh::log error dotfiles "~/.hushlogin missing"
        drift=1
      fi
      if [[ $OSTYPE == darwin* ]]; then
        if _dotfiles_encoding_ok; then
          _zsh::log success dotfiles "text encoding OK"
        else
          _zsh::log error dotfiles "~/.CFUserTextEncoding missing"
          drift=1
        fi
        if _dotfiles_vscode_ok "$vscode_settings" "$vscode_tracked"; then
          _zsh::log success dotfiles "VS Code settings symlink OK"
        else
          _zsh::log error dotfiles "VS Code settings is not a symlink to the tracked file"
          drift=1
        fi
        local -a missing_extensions
        missing_extensions=(${(f)"$(_dotfiles_vscode_extensions)"})
        if (( $#missing_extensions == 0 )); then
          _zsh::log success dotfiles "VS Code extensions OK"
        else
          _zsh::log error dotfiles "missing VS Code extensions: ${(j:, :)missing_extensions}"
          drift=1
        fi
      fi
      (( drift == 0 )) && _zsh::log info dotfiles "no drift detected ✨"
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
      _zsh::log error dotfiles "unknown command: $1"
      print -r --
      dotfiles --help
      return 1
      ;;
  esac
}
