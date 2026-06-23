# Wrap brew/mas so package-mutating commands sync the Brewfile in the background.
#
# Usage: brew <command>
#        mas <command>

_brewfile_sync() {
  emulate -L zsh
  if ! { command brew bundle dump --brews --casks --taps --mas --force --no-restart &&
    command brew bundle } &>/dev/null; then
    print -r -- 'brewfile: background Brewfile sync failed' >&2
  fi
}

brew() {
  emulate -L zsh

  # Subcommands that mutate installed packages, so a sync follows.
  local -a dump_commands=(
    install uninstall remove reinstall upgrade cleanup
    link unlink pin unpin tap untap
  )

  local cmd=$1
  (( $# )) && shift

  case $cmd in
    dump)
      command brew bundle dump --brews --casks --taps --mas --force --no-restart "$@"
      ;;
    fresh)
      command brew update &&
        command brew upgrade &&
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

      # Membership test: 1 when $cmd is in dump_commands.
      # Skip the sync when the command only printed help.
      if (( ${dump_commands[(Ie)$cmd]} )) && (( exit == 0 )) &&
        (( ! ${@[(Ie)-h]} )) && (( ! ${@[(Ie)--help]} )); then
        # Run the sync detached so the prompt returns immediately.
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

# Register completion only when compdef and functions exist.
if (( $+functions[compdef] )); then
  (( $+functions[_brew] )) && compdef _brew brew
  (( $+functions[_mas] )) && compdef _mas mas
fi
