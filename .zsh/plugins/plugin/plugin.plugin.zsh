(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

_plugin_path() {
  emulate -L zsh
  local name="$1"
  local custom="$ZSH_CUSTOM/plugins/$name/$name.plugin.zsh"
  if [[ -f "$custom" ]]; then
    REPLY="$custom"
    return 0
  fi
  local default="$ZSH/plugins/$name/$name.plugin.zsh"
  [[ -f "$default" ]] || return 1
  REPLY="$default"
  return 0
}

_plugin_update_one() {
  emulate -L zsh
  local name="$1" dir="$ZSH_CUSTOM/plugins/$1"

  if [[ ! -d "$dir/.git" ]]; then
    _zsh::log error plugin "no remote: $name"
    return 1
  fi

  local -a lines
  lines=("${(@f)"$(command git -C "$dir" ls-remote --symref origin HEAD 2>/dev/null)"}")
  if (( ${#lines} < 2 )); then
    _zsh::log error plugin "failed to reach remote: $name"
    return 1
  fi

  local branch="${lines[1]#ref: refs/heads/}"
  branch="${branch%%$'\t'*}"
  local remote_head="${lines[2]%%$'\t'*}"
  local local_head="$(command git -C "$dir" rev-parse HEAD 2>/dev/null)"

  if [[ "$local_head" == "$remote_head" ]]; then
    _zsh::log info plugin "$name is up to date"
    return 0
  fi

  if command git -C "$dir" fetch --depth 1 origin "$branch" &>/dev/null &&
    command git -C "$dir" reset --hard FETCH_HEAD &>/dev/null; then
    _zsh::log success plugin "$name updated to ${remote_head[1,7]}"
  else
    _zsh::log error plugin "failed to update: $name"
    return 1
  fi
}

plugin() {
  emulate -L zsh
  local REPLY

  case "$1" in
    load)
      shift
      if (( $# == 0 )); then
        _zsh::log error plugin 'load requires at least one plugin name'
        return 1
      fi

      local name
      integer rc=0
      for name in "$@"; do
        if _plugin_path "$name"; then
          source "$REPLY"
        else
          _zsh::log error plugin "not found: $name"
          rc=1
        fi
      done
      return rc
      ;;

    update)
      shift
      local -a names
      local name
      if (( $# > 0 )); then
        names=("$@")
      else
        for name in "$ZSH_CUSTOM/plugins"/*(/N:t); do
          [[ -d "$ZSH_CUSTOM/plugins/$name/.git" ]] && names+=("$name")
        done
      fi

      integer rc=0
      for name in "${names[@]}"; do
        _plugin_update_one "$name" || rc=1
      done
      return rc
      ;;

    help|-h|--help|"")
      print -r -- 'Usage: plugin <command>'
      print
      print -r -- 'Commands:'
      print -r -- '    load <name...>     Load one or more plugins by name.'
      print -r -- '    update [name...]   Update custom plugins with a remote, or all of them.'
      print -r -- '    help               Show this message.'
      return 0
      ;;

    *)
      _zsh::log error plugin "unknown command: $1"
      plugin help
      return 1
      ;;
  esac
}
