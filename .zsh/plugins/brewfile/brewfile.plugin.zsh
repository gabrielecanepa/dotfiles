(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

_brewfile_dump() {
  emulate -L zsh
  local file=${HOMEBREW_BUNDLE_FILE:-Brewfile} tmp mode
  file=${file:a}
  tmp=$(command mktemp "$file.XXXXXX") || return 1
  mode=$(command stat -f '%Lp' "$file" 2>/dev/null)
  command chmod "${mode:-644}" "$tmp"
  if command brew bundle dump --brews --casks --taps --mas --force --no-restart --file="$tmp" && [[ -s $tmp ]]; then
    command mv -f "$tmp" "$file"
    return $?
  fi
  command rm -f "$tmp"
  return 1
}

_brewfile_sync() {
  emulate -L zsh
  if ! _brewfile_dump &>/dev/null; then
    _zsh::log warn brewfile 'background Brewfile sync failed'
  fi
}

_brewfile_drift() {
  emulate -L zsh
  (( $+commands[brew] )) || return 0
  local file=${HOMEBREW_BUNDLE_FILE:-Brewfile}
  file=${file:a}
  [[ -f $file ]] || return 0
  local -a lines
  lines=(${(f)"$(HOMEBREW_NO_AUTO_UPDATE=1 command brew bundle check --verbose --file="$file" 2>&1)"})
  local line kind name
  for line in $lines; do
    [[ $line == '→ '* ]] || continue
    line=${line#'→ '}
    kind=${line%% *}
    name=${${line#* }%% *}
    print -r -- "${(L)kind} $name"
  done
  return 0
}

brew() {
  emulate -L zsh

  local -a dump_commands=(
    install uninstall remove reinstall upgrade
		cleanup link unlink pin unpin tap untap
  )

  local cmd=$1
  (( $# )) && shift

  case $cmd in
    dump)
      if (( $# )); then
        command brew bundle dump --brews --casks --taps --mas --force --no-restart "$@"
      else
        _brewfile_dump
      fi
      ;;
    fresh)
      local -a upgrade_args=()
      if (( ${@[(Ie)--no-casks]} )); then
        upgrade_args=(--formula)
      fi

      command brew update &&
        command brew upgrade "${upgrade_args[@]}" &&
        { (( ${@[(Ie)--no-mas]} )) || sudo command mas upgrade; } &&
        command brew cleanup --prune=all &&
        brew dump &&
        command brew doctor
      ;;
    global)
      command brew bundle "$@"
      ;;
    check)
      command brew bundle check --verbose "$@"
      ;;
    reset)
      command brew update-reset "$@"
      ;;
    *)
      command brew "$cmd" "$@"
      local exit=$?

      if (( ${dump_commands[(Ie)$cmd]} )) && (( exit == 0 )) &&
        (( ! ${@[(Ie)-h]} )) && (( ! ${@[(Ie)--help]} )); then
        _brewfile_sync &!
      fi

      return $exit
      ;;
  esac
}

mas() {
  emulate -L zsh

  local -a dump_commands=(install uninstall upgrade)

  local cmd=$1
  local in_dump=${dump_commands[(Ie)$cmd]}

  if (( in_dump )); then
    sudo command mas "$@"
  else
    command mas "$@"
  fi
  local exit=$?

  if (( in_dump )) && (( exit == 0 )); then
    _brewfile_sync &!
  fi

  return $exit
}

if (( $+functions[compdef] )); then
  (( $+functions[_brew] )) && compdef _brew brew
  (( $+functions[_mas] )) && compdef _mas mas
fi
