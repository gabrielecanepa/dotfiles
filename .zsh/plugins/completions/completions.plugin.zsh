#!/bin/zsh

# Set completions path
[[ -z "$ZSH_COMPLETIONS" ]] && export ZSH_COMPLETIONS="$ZSH_CUSTOM/completions"
[[ ! -d "$ZSH_COMPLETIONS" ]] && mkdir -p "$ZSH_COMPLETIONS"

function completions() {
  local clis=($@)
  local comp
  read -u0 -t comp

  [[ ${#clis[@]} == 0 ]] && echo "Usage: completions <cli> [<cli> ...]" && return 1

  if [[ -n "$comp" ]]; then
    [[ ${#clis[@]} > 1 ]] && echo "Error: only one cli can be passed when using stdin" && return 1
    echo "$comp" > "$ZSH_COMPLETIONS/_${clis[0]}"
  else
    for cli in $clis; do
      ! command -v $cli >/dev/null && echo "Command not found: $cli" && return 1
      local comp="$(eval "$cli completion zsh")"

      if [[ -z "$comp" ]] ; then
        echo "Error: no completions found for $cli"
        continue
      fi

      echo $comp > "$ZSH_COMPLETIONS/_$cli"
    done; unset cli
  fi
}
