_node_version_current() {
  emulate -L zsh
  local raw version
  (( $+commands[node] )) || { print -ru2 -- 'node-version: node not found'; return 1; }
  raw=$(command node -v) || { print -ru2 -- 'node-version: node -v failed'; return 1; }
  version=${raw#v}
  [[ -n $version ]] || { print -ru2 -- 'node-version: empty node version'; return 1; }
  print -r -- $version
}

node-version() {
  emulate -L zsh
  local MATCH MBEGIN MEND match mbegin mend

  if (( $# > 2 )) || { (( $# > 1 )) && [[ $1 != pin ]]; }; then
    print -ru2 -- "node-version: unknown arguments: ${*:2}"
    print -ru2 -- 'usage: node-version [pin [X.Y.Z]]'
    return 1
  fi

  case $1 in
    -h|--help)
      print -r -- 'node-version [pin [X.Y.Z]]'
      print -r -- ''
      print -r -- 'Print the running Node.js version or pin a version to .node-version.'
      ;;
    '')
      _node_version_current
      ;;
    pin)
      local version
      if (( $# == 2 )); then
        version=$2
        if [[ ! $version =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
          print -ru2 -- "node-version: invalid version: $version (expected X.Y.Z)"
          return 1
        fi
      else
        version=$(_node_version_current) || return 1
      fi
      print -r -- $version > ./.node-version
      ;;
    *)
      print -ru2 -- "node-version: unknown option: $1"
      print -ru2 -- 'usage: node-version [pin [X.Y.Z]]'
      return 1
      ;;
  esac
}
