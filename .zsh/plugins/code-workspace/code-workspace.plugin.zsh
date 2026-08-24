(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

[[ -z "${VSCODE_WORKSPACES_PATH:-}" ]] && export VSCODE_WORKSPACES_PATH="$HOME/.vscode/workspaces"

code-workspace() {
  emulate -L zsh

  local name="$1"

  if [[ -z "$name" || "$name" == "-h" || "$name" == "--help" ]]; then
    print -r -- 'Usage: code-workspace <name>'
    return 0
  fi

  local file="$VSCODE_WORKSPACES_PATH/$name.code-workspace"
  if [[ ! -f "$file" ]]; then
    _zsh::log error code-workspace "not found: $name"
    return 1
  fi

  command code "$file"
}
