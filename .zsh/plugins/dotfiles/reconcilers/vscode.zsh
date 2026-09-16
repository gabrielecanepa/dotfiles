# Reconciles the VS Code extensions listed in ~/.vscode/extensions.json against the installed set.

_vscode_missing() {
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

_vscode_drift() {
  emulate -L zsh
  local id
  for id in ${(f)"$(_vscode_missing)"}; do
    print -r -- "missing $id"
  done
  return 0
}

_vscode_reconcile() {
  emulate -L zsh
  integer verbose=${1:-0}
  local -a missing
  missing=(${(f)"$(_vscode_missing)"})

  if (( $#missing == 0 )); then
    (( verbose )) && _zsh::log info vscode "extensions synced"
    return 0
  fi

  if ! (( $+commands[code] )); then
    _zsh::log warn vscode "code CLI not found, skipping $#missing missing extension(s)"
    return 0
  fi

  local extension
  for extension in $missing; do
    if command code --install-extension "$extension" >/dev/null 2>&1; then
      _zsh::log success vscode "extension $extension installed"
    else
      _zsh::log warn vscode "failed to install extension $extension"
    fi
  done

  return 0
}
