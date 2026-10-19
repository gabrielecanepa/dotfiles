: ${VSCODE_WORKSPACES_DIR:=~/.vscode/workspaces}

code-workspace() {
  emulate -L zsh

  local name=$1

  if [[ -z $name || $name == -h || $name == --help ]]; then
    print -r -- 'Usage: code-workspace <name>'
    return 0
  fi

  local file=$VSCODE_WORKSPACES_DIR/$name.code-workspace
  if [[ ! -f $file ]]; then
    print -ru2 -- "code-workspace: not found: $name"
    return 1
  fi

  command code $file
}
