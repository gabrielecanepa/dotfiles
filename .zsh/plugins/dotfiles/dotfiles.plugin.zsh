(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

typeset -g _dotfiles_dir="${0:A:h}"

typeset -ga ZSH_DOTFILES_RECONCILERS
(( $#ZSH_DOTFILES_RECONCILERS )) || ZSH_DOTFILES_RECONCILERS=(launchd vscode npm-global brewfile)

for _dotfiles_reconciler in "$_dotfiles_dir"/reconcilers/*.zsh(N); do
  builtin source "$_dotfiles_reconciler"
done
unset _dotfiles_reconciler

dotfiles() {
  emulate -L zsh

  case "$1" in
    init|"")
      integer rc=0 verbose=0
      [[ "$2" == (-v|--verbose) ]] && verbose=1

      if (( $+functions[initialize-path] )); then
        initialize-path
        (( verbose )) && _zsh::log info dotfiles "path reinitialized"
      else
        _zsh::log error dotfiles "initialize-path is not defined"
        rc=1
      fi

      local aliases_file="${ZSH_ALIASES:-$HOME/.aliases}"
      if [[ -r "$aliases_file" ]]; then
        builtin source "$aliases_file"
        (( verbose )) && _zsh::log info dotfiles "aliases sourced"
      else
        _zsh::log warn dotfiles "aliases file missing at ${aliases_file/#$HOME/~}"
      fi

      local name fn
      for name in $ZSH_DOTFILES_RECONCILERS; do
        fn="_${name//-/_}_reconcile"
        (( $+functions[$fn] )) || continue
        $fn $verbose || rc=1
      done

      return rc
      ;;
    doctor)
      integer drift=0
      if (( $+functions[initialize-path] )); then
        _zsh::log success dotfiles "initialize-path OK"
      else
        _zsh::log error dotfiles "initialize-path is not defined"
        drift=1
      fi

      local aliases_file="${ZSH_ALIASES:-$HOME/.aliases}"
      if [[ -r "$aliases_file" ]]; then
        _zsh::log success dotfiles "aliases file OK"
      else
        _zsh::log error dotfiles "aliases file missing at ${aliases_file/#$HOME/~}"
        drift=1
      fi

      local name fn state
      local -a lines items
      for name in $ZSH_DOTFILES_RECONCILERS; do
        fn="_${name//-/_}_drift"
        (( $+functions[$fn] )) || continue
        lines=(${(f)"$($fn)"})
        if (( $#lines == 0 )); then
          _zsh::log success dotfiles "$name OK"
          continue
        fi
        for state in ${(u)${lines%% *}}; do
          items=(${${(M)lines:#$state *}#$state })
          _zsh::log error dotfiles "$name $state: ${(j:, :)items}"
        done
        drift=1
      done

      (( drift == 0 )) && _zsh::log success dotfiles "no drift detected"
      return drift
      ;;
    help|-h|--help)
      print -r -- "Usage: dotfiles <command>"
      print -r --
      print -r -- "Commands:"
      print -r -- "    init [-v|--verbose]   Fix any drifted state, silently unless verbose (default; idempotent)."
      print -r -- "    doctor                Report drift without changing anything."
      print -r -- "    help                  Show this message."
      ;;
    *)
      _zsh::log error dotfiles "unknown command: $1"
      print -r --
      dotfiles --help
      return 1
      ;;
  esac
}
