_brewfile_global_file() {
  if [[ -n ${HOMEBREW_BUNDLE_FILE_GLOBAL:-} ]]; then
    print -r -- $HOMEBREW_BUNDLE_FILE_GLOBAL
  elif [[ -n ${XDG_CONFIG_HOME:-} ]]; then
    print -r -- $XDG_CONFIG_HOME/homebrew/Brewfile
  elif [[ -f ~/.homebrew/Brewfile || ! -f ~/.Brewfile ]]; then
    print -r -- ~/.homebrew/Brewfile
  else
    print -r -- ~/.Brewfile
  fi
}

_brewfile_dump() {
  emulate -L zsh
  local file=$(_brewfile_global_file) tmp mode
  file=${file:a}
  tmp=$(command mktemp $file.XXXXXX) || return 1
  mode=$(command stat -f '%Lp' $file 2>/dev/null)
  command chmod ${mode:-644} $tmp
  if command brew bundle dump --brews --casks --taps --mas --force --no-restart --file=$tmp && [[ -s $tmp ]]; then
    command mv -f $tmp $file
    return $?
  fi
  command rm -f $tmp
  return 1
}

_brewfile_sync() {
  emulate -L zsh
  if ! _brewfile_dump &>/dev/null; then
    print -ru2 -- 'brewfile: Brewfile sync failed'
  fi
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
        { (( ${@[(Ie)--no-mas]} )) || sudo mas upgrade; } &&
        command brew cleanup --prune=all &&
        brew dump &&
        command brew doctor
      ;;
    global)
      command brew bundle --global "$@"
      ;;
    check)
      command brew bundle check --global --verbose "$@"
      ;;
    reset)
      command brew update-reset "$@"
      ;;
    *)
      command brew $cmd "$@"
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
    sudo mas "$@"
  else
    command mas "$@"
  fi
  local exit=$?

  if (( in_dump )) && (( exit == 0 )); then
    _brewfile_sync &!
  fi

  return $exit
}

_brewfile_extend_completions() {
  emulate -L zsh
  (( ${+_brewfile_completions_extended} )) && return 0
  (( $+functions[__brew_internal_commands] )) || return 0
  local body=${functions[__brew_internal_commands]}
  local original=$body
  local -a additions=(
    "    'check:Check the global Brewfile'"
    "    'dump:Write the Brewfile'"
    "    'fresh:Update, upgrade, clean, and doctor'"
    "    'global:Run brew bundle --global'"
    "    'reset:Run brew update-reset'"
  )
  local insertion=$'  commands+=(\n'
  local addition
  for addition in "${additions[@]}"; do
    insertion+=$addition$'\n'
  done
  insertion+=$'\n  )\n  commands=("${(@on)commands}")\n'
  local target="_describe -t internal-commands 'internal commands' commands"
  body=${body//$target/${insertion}${target}}
  [[ $body == $original ]] && return 0
  eval "__brew_internal_commands() { ${body}"$'\n}' || return 1
  typeset -g _brewfile_completions_extended=1
}

_brewfile_completions() {
  _brewfile_extend_completions
  _brew "$@"
}

(( $+functions[_brew_dump] )) || _brew_dump() { return 0 }
(( $+functions[_brew_global] )) || _brew_global() { return 0 }
(( $+functions[_brew_check] )) || _brew_check() { return 0 }
(( $+functions[_brew_reset] )) || _brew_reset() { return 0 }
(( $+functions[_brew_fresh] )) || _brew_fresh() {
  _arguments \
    '--no-casks[Skip cask upgrades]' \
    '--no-mas[Skip Mac App Store upgrades]'
}

if (( $+functions[compdef] )); then
  (( $+functions[_brew] )) && compdef _brewfile_completions brew
  (( $+functions[_mas] )) && compdef _mas mas
fi
