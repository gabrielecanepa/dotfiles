#
# node: utilities to print/dump the running Node.js version and keep the current project's node_modules/.bin on PATH.
# Usage: node-version [dump]

(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

node-version() {
  emulate -L zsh
  setopt warn_create_global

  local raw version

  case "$1" in
    -h|--help)
      print -r -- 'node-version [dump]'
      print -r -- ''
      print -r -- 'Print or dumps to .node-version the running Node.js version.'
      ;;
    '')
      (( $+commands[node] )) || { _zsh::log error node-version 'node not found'; return 1; }
      raw="$(command node -v)" || { _zsh::log error node-version 'node -v failed'; return 1; }
      # Strip the leading v (v22.1.0 -> 22.1.0)
      version="${raw#v}"
      [[ -n "$version" ]] || { _zsh::log error node-version 'empty node version'; return 1; }
      print -r -- "$version"
      ;;
    dump)
      (( $+commands[node] )) || { _zsh::log error node-version 'node not found'; return 1; }
      raw="$(command node -v)" || { _zsh::log error node-version 'node -v failed'; return 1; }
      version="${raw#v}"
      [[ -n "$version" ]] || { _zsh::log error node-version 'empty node version'; return 1; }
      print -r -- "$version" > ./.node-version
      ;;
    *)
      _zsh::log error node-version "unknown option: $1"
      print -ru2 -- 'usage: node-version [dump]'
      return 1
      ;;
  esac
}

_node_local_bin_update() {
  emulate -L zsh

  # Remove the marked entry from a prior run so PATH does not accumulate.
  if [[ -n "$_NODE_LOCAL_BIN_CURRENT" ]]; then
    path=("${(@)path:#$_NODE_LOCAL_BIN_CURRENT}")
    unset _NODE_LOCAL_BIN_CURRENT
  fi

  local dir="$PWD"
  while [[ -n "$dir" ]]; do
    if [[ -d "$dir/node_modules/.bin" ]]; then
      # Append, a project's local binary must not shadow a real system command.
      path+=("$dir/node_modules/.bin")
      typeset -g _NODE_LOCAL_BIN_CURRENT="$dir/node_modules/.bin"
      return 0
    fi
    [[ "$dir" == / ]] && break
    dir="${dir:h}"
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _node_local_bin_update
_node_local_bin_update
