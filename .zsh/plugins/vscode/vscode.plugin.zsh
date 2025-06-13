#!/bin/zsh

function vscode() {
  if ! command -v code >/dev/null; then
    echo "VSCode command line tool not found."
    return 1
  fi

  local input="$1"
  [[ -z "$input" ]] && return 1

  local working_dir="$WORKING_DIR"
  [[ -z "$working_dir" ]] && working_dir="$HOME"

  local target="$working_dir/$input"
  [[ ! -d "$target" && ! -f "$target" ]] && return 1

  command code "$target"
}
