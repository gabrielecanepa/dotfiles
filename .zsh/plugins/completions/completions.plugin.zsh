#!/bin/zsh

function completions() {
  if [[ -z "$ZSH_COMPLETIONS" ]]; then
    local ZSH_COMPLETIONS="$ZSH/completions"
  fi
  [[ ! -d "$ZSH_COMPLETIONS" ]] && mkdir -p "$ZSH_COMPLETIONS"

  local cmd="$1"
  local args=(${@:2})
  
  case "$cmd" in
    generate)
      for arg in "${args[@]}"; do
        if ! command -v "$arg" &>/dev/null; then
          echo "[zsh-plugin-completions] command not found: $arg"
          return 1
        fi

        local completions="$(eval "$arg completion zsh")"

        if [[ -z "$completions" ]] ; then
          echo "no completions found for $arg"
          return 1
        fi

        echo $completions > "$ZSH_COMPLETIONS/_$arg"
      done
      ;;
    *)
      echo "Usage: completions generate <command>"
      return 1
      ;;
  esac
}
