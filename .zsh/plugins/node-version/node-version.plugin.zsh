#
# node-version: print the running Node version (leading "v" stripped), or dump it to ./.node-version.
# Usage: node-version [dump]
#

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
      # Strip the leading v (v22.1.0 -> 22.1.0).
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
