#!/bin/zsh

# Set completions path
[[ -z "$ZSH_COMPLETIONS_PATH" ]] && export ZSH_COMPLETIONS_PATH="$ZSH_CUSTOM/completions"
[[ ! -d "$ZSH_COMPLETIONS_PATH" ]] && mkdir -p "$ZSH_COMPLETIONS_PATH"

function completions() {
  local clis=($@)
  local comp
  read -u0 -t comp

  [[ ${#clis[@]} == 0 ]] && echo "Usage: completions <cli> [<cli> ...]" && return 1

  if [[ -n "$comp" ]]; then
    [[ ${#clis[@]} > 1 ]] && echo "Error: only one cli can be passed when using stdin" && return 1
    echo "$comp" > "$ZSH_COMPLETIONS_PATH/_${clis[0]}"
  else
    for cli in $clis; do
      ! command -v $cli >/dev/null && echo "[completions] Command not found: $cli" && return 1
      local comp="$(eval "$cli completion zsh" 2>/dev/null)"
      [[ -z "$comp" ]] && comp="$(eval "$cli completion --zsh" 2>/dev/null)"
      [[ -z "$comp" ]] && comp="$(eval "$cli completion" 2>/dev/null)"

      if [[ -z "$comp" ]] ; then
        echo "[completions] Error: can't find completions for $cli"
        continue
      fi

      echo $comp > "$ZSH_COMPLETIONS_PATH/_$cli"
    done; unset cli
  fi
}
