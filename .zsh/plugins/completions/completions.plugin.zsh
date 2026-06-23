# Generate and cache zsh completion files under $ZSH_COMPLETIONS_PATH.
#
# Usage: completions <cli> [<cli> ...]

[[ -z "${ZSH_COMPLETIONS_PATH:-}" ]] && export ZSH_COMPLETIONS_PATH="${ZSH_CUSTOM:-$HOME/.zsh}/completions"
[[ -d "$ZSH_COMPLETIONS_PATH" ]] || mkdir -p "$ZSH_COMPLETIONS_PATH"

completions() {
  emulate -L zsh

  local -a clis=("$@")
  local cli comp
  integer rc=0

  if (( ${#clis[@]} == 0 )); then
    print -ru2 -- '[completions] usage: completions <cli> [<cli> ...]'
    return 1
  fi

  # Read piped/redirected completion text only when stdin is a pipe or regular
  # file; this skips the no-redirect and /dev/null cases so the startup loop
  # below never blocks on read.
  if [[ -p /dev/stdin || -f /dev/stdin ]]; then
    IFS= read -rd '' comp

    if (( ${#clis[@]} > 1 )); then
      print -ru2 -- '[completions] only one cli can be passed when using stdin'
      return 1
    fi

    if ! print -r -- "$comp" > "$ZSH_COMPLETIONS_PATH/_${clis[1]}"; then
      print -ru2 -- "[completions] failed to write completions for ${clis[1]}"
      return 1
    fi

    return 0
  fi

  local file
  for cli in "${clis[@]}"; do
    if (( ! ${+commands[$cli]} )); then
      print -ru2 -- "[completions] command not found: $cli"
      rc=1
      continue
    fi

    # Probe the common completion-subcommand spellings, get first non-empty.
    comp="$(command "$cli" completion zsh 2>/dev/null)"
    [[ -n "$comp" ]] || comp="$(command "$cli" completion --zsh 2>/dev/null)"
    [[ -n "$comp" ]] || comp="$(command "$cli" completion 2>/dev/null)"

    if [[ -z "$comp" ]]; then
      print -ru2 -- "[completions] cannot generate completions for $cli"
      rc=1
      continue
    fi

    # Skip the write when the cache already matches the probed output.
    file="$ZSH_COMPLETIONS_PATH/_$cli"
    [[ -e "$file" && "$comp" == "$(<"$file")" ]] && continue

    if ! print -r -- "$comp" > "$file"; then
      print -ru2 -- "[completions] failed to write completions for $cli"
      rc=1
      continue
    fi
  done

  return $rc
}

# At startup, generate any missing completion inline to make it available in
# the session, then re-probe the caches in a detached background job so stal
# caches are refreshed for the next shell without blocking the current.
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
