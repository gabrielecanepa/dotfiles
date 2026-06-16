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

    if ! print -r -- "$comp" > "$ZSH_COMPLETIONS_PATH/_$cli"; then
      print -ru2 -- "[completions] failed to write completions for $cli"
      rc=1
      continue
    fi
  done

  return $rc
}

# At startup, generate any configured completion that is not cached yet.
for cli in ${ZSH_COMPLETIONS:-}; do
  [[ -e "$ZSH_COMPLETIONS_PATH/_$cli" ]] || completions "$cli"
done
unset cli
