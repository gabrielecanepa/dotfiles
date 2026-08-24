(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

[[ -z "${ZSH_COMPLETIONS_PATH:-}" ]] && export ZSH_COMPLETIONS_PATH="${ZSH_CUSTOM:-$HOME/.zsh}/completions"
[[ -d "$ZSH_COMPLETIONS_PATH" ]] || mkdir -p "$ZSH_COMPLETIONS_PATH"

completions() {
  emulate -L zsh

  local -a clis=("$@")
  local cli comp
  integer rc=0

  if (( ${#clis[@]} == 0 )); then
    _zsh::log error completions 'usage: completions <cli> [<cli> ...]'
    return 1
  fi

  # Read completion text only when stdin is a pipe or regular file, so the startup loop never blocks on read.
  if [[ -p /dev/stdin || -f /dev/stdin ]]; then
    IFS= read -rd '' comp

    if (( ${#clis[@]} > 1 )); then
      _zsh::log error completions 'only one cli can be passed when using stdin'
      return 1
    fi

    if ! print -r -- "$comp" > "$ZSH_COMPLETIONS_PATH/_${clis[1]}"; then
      _zsh::log error completions "failed to write completions for ${clis[1]}"
      return 1
    fi

    return 0
  fi

  local file
  for cli in "${clis[@]}"; do
    if (( ! ${+commands[$cli]} )); then
      _zsh::log error completions "command not found: $cli"
      rc=1
      continue
    fi

    comp="$(command "$cli" completion zsh 2>/dev/null)"
    [[ -n "$comp" ]] || comp="$(command "$cli" completion --zsh 2>/dev/null)"
    [[ -n "$comp" ]] || comp="$(command "$cli" completion 2>/dev/null)"

    if [[ -z "$comp" ]]; then
      _zsh::log error completions "cannot generate completions for $cli"
      rc=1
      continue
    fi

    file="$ZSH_COMPLETIONS_PATH/_$cli"
    [[ -e "$file" && "$comp" == "$(<"$file")" ]] && continue

    if ! print -r -- "$comp" > "$file"; then
      _zsh::log error completions "failed to write completions for $cli"
      rc=1
      continue
    fi
  done

  return $rc
}

# Generate missing completions and refresh existing caches in the background.
() {
  local cli
  local -a cached
  for cli in ${ZSH_COMPLETIONS:-}; do
    if [[ -e "$ZSH_COMPLETIONS_PATH/_$cli" ]]; then
      cached+=("$cli")
    else
      completions "$cli"
    fi
  done
  (( ${#cached} )) && { completions "${cached[@]}" &> /dev/null &! }
}
