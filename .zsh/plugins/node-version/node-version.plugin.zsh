# Print the running node major.minor.patch with the leading "v" stripped, or write it to ./.node-version.
#
# Usage: node-version [dump]

node-version() {
  emulate -L zsh
  # Flag any unintended global assignment inside the function so the locals below stay scoped.
  setopt warn_create_global

  local raw version

  case "$1" in
    ''|-h|--help)
      (( $+commands[node] )) || { print -r -- 'node-version: node not found' >&2; return 1; }
      raw="$(command node -v)" || { print -r -- 'node-version: node -v failed' >&2; return 1; }
      # Strip the leading v from node -v output (v22.1.0 -> 22.1.0).
      version="${raw#v}"
      [[ -n "$version" ]] || { print -r -- 'node-version: empty node version' >&2; return 1; }
      print -r -- "$version"
      ;;
    dump)
      (( $+commands[node] )) || { print -r -- 'node-version: node not found' >&2; return 1; }
      raw="$(command node -v)" || { print -r -- 'node-version: node -v failed' >&2; return 1; }
      version="${raw#v}"
      [[ -n "$version" ]] || { print -r -- 'node-version: empty node version' >&2; return 1; }
      # Pin the current version for nodenv in the working directory.
      print -r -- "$version" > ./.node-version
      ;;
    *)
      print -r -- "node-version: unknown option: $1" >&2
      print -r -- 'usage: node-version [dump]' >&2
      return 1
      ;;
  esac
}
