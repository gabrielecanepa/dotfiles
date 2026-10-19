typeset -g _completions_dir=${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-~/.cache}/zsh}/completions
(( ${fpath[(Ie)$_completions_dir]} )) || fpath=($_completions_dir $fpath)

_completions::load() {
  emulate -L zsh
  local cli=$1 comp=$2
  local -a words
  (( $+functions[compdef] )) || return 0
  [[ $comp == '#compdef '* ]] || return 0
  words=(${=comp%%$'\n'*})
  shift words
  (( ${#words} )) || return 0
  autoload -U _$cli 2>/dev/null || return 0
  compdef _$cli "${words[@]}" 2>/dev/null
}

completions() {
  emulate -L zsh

  local -a clis=("$@")
  local cli comp
  integer rc=0

  if (( ${#clis[@]} == 0 )); then
    print -ru2 -- 'Usage: completions <cli> [<cli>...]'
    return 1
  fi

  command mkdir -p $_completions_dir || return 1

  if [[ -p /dev/stdin || -f /dev/stdin ]]; then
    IFS= read -rd '' comp || :

    if (( ${#clis[@]} > 1 )); then
      print -ru2 -- 'completions: only one CLI can be passed when using stdin'
      return 1
    fi

    if [[ $comp != '#compdef '* ]]; then
      print -ru2 -- "completions: invalid Zsh completions for ${clis[1]}"
      return 1
    fi

    if ! print -r -- $comp > $_completions_dir/_${clis[1]}; then
      print -ru2 -- "completions: failed to write completions for ${clis[1]}"
      return 1
    fi

    _completions::load "${clis[1]}" "$comp"
    return 0
  fi

  local file
  for cli in "${clis[@]}"; do
    if (( ! ${+commands[$cli]} )); then
      print -ru2 -- "completions: command not found: $cli"
      rc=1
      continue
    fi

    comp=$(command $cli completion zsh 2>/dev/null)
    [[ $comp == '#compdef '* ]] || comp=$(command $cli completion --zsh 2>/dev/null)
    [[ $comp == '#compdef '* ]] || comp=$(command $cli completion -s zsh 2>/dev/null)
    [[ $comp == '#compdef '* ]] || comp=$(command $cli completion 2>/dev/null)
    [[ $comp == '#compdef '* ]] || comp=$(command $cli --completions zsh 2>/dev/null)

    if [[ $comp != '#compdef '* ]]; then
      print -ru2 -- "completions: cannot generate Zsh completions for $cli"
      rc=1
      continue
    fi

    file=$_completions_dir/_$cli
    if [[ -e $file && $comp == "$(<$file)" ]]; then
      command touch -- $file
      _completions::load $cli $comp
      continue
    fi

    if ! print -r -- $comp > $file; then
      print -ru2 -- "completions: failed to write completions for $cli"
      rc=1
      continue
    fi

    _completions::load $cli $comp
  done

  return $rc
}

() {
  emulate -L zsh
  local cli file
  local -a stale cache_time link_time bin_time
  zmodload -F zsh/stat b:zstat 2>/dev/null
  for cli in ${completions:-}; do
    file=$_completions_dir/_$cli
    if [[ -e $file ]]; then
      _completions::load $cli "$(<$file)"
      (( ${+commands[$cli]} )) || continue
      zstat -A cache_time +mtime -- $file &&
        zstat -L -A link_time +mtime -- $commands[$cli] &&
        zstat -A bin_time +mtime -- $commands[$cli] || continue
      (( link_time[1] > cache_time[1] || bin_time[1] > cache_time[1] )) && stale+=($cli)
    else
      completions $cli </dev/null &>/dev/null
    fi
  done
  (( ${#stale} )) && { completions "${stale[@]}" </dev/null &>/dev/null &! }
  return 0
}
