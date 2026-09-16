# Reconciles the tracked launch agents under ~/Library/LaunchAgents against launchd.

_launchd_agents() {
  emulate -L zsh
  [[ $OSTYPE == darwin* && -d "$HOME/.git" ]] || return 0
  local -a files
  files=(${(0)"$(command git -C "$HOME" ls-files -z --cached --others --exclude-standard -- 'Library/LaunchAgents/*.plist' 2>/dev/null)"})
  local file
  for file in $files; do
    print -r -- "$HOME/$file"
  done
  return 0
}

_launchd_disabled() {
  emulate -L zsh
  setopt local_options extended_glob
  [[ "$(<"$1")" == *'<key>Disabled</key>'[[:space:]]#'<true/>'* ]]
}

_launchd_loaded() {
  emulate -L zsh
  command launchctl print "gui/$UID/$1" &>/dev/null
}

_launchd_marker() {
  emulate -L zsh
  REPLY="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/launchd/$1"
}

_launchd_unload() {
  emulate -L zsh
  command launchctl bootout "gui/$UID/$1" 2>/dev/null
  local tries=0
  while (( tries++ < 30 )) && _launchd_loaded "$1"; do
    command sleep 0.1
  done
  ! _launchd_loaded "$1"
}

_launchd_stale() {
  emulate -L zsh
  local plist label REPLY
  for plist in ${(f)"$(_launchd_agents)"}; do
    _launchd_disabled "$plist" && continue
    label="${plist:t:r}"
    _launchd_marker "$label"
    [[ -e "$REPLY" && ! "$plist" -nt "$REPLY" ]] && _launchd_loaded "$label" && continue
    print -r -- "$plist"
  done
  return 0
}

_launchd_retired() {
  emulate -L zsh
  local plist
  for plist in ${(f)"$(_launchd_agents)"}; do
    _launchd_disabled "$plist" || continue
    _launchd_loaded "${plist:t:r}" && print -r -- "$plist"
  done
  return 0
}

_launchd_drift() {
  emulate -L zsh
  local plist
  for plist in ${(f)"$(_launchd_stale)"}; do
    print -r -- "stale ${plist:t:r}"
  done
  for plist in ${(f)"$(_launchd_retired)"}; do
    print -r -- "retired ${plist:t:r}"
  done
  return 0
}

_launchd_reconcile() {
  emulate -L zsh
  integer verbose=${1:-0} rc=0
  local -a stale retired
  stale=(${(f)"$(_launchd_stale)"})
  retired=(${(f)"$(_launchd_retired)"})

  if (( $#stale == 0 )); then
    (( verbose )) && _zsh::log info launchd "agents loaded"
  else
    local plist label REPLY
    for plist in $stale; do
      label="${plist:t:r}"
      _launchd_marker "$label"
      _launchd_unload "$label"
      if command launchctl bootstrap "gui/$UID" "$plist" 2>/dev/null &&
        command mkdir -p "${REPLY:h}" && command touch "$REPLY"; then
        _zsh::log success launchd "agent $label loaded"
      else
        _zsh::log warn launchd "failed to load agent $label"
      fi
    done
  fi

  local agent
  for agent in $retired; do
    if _launchd_unload "${agent:t:r}"; then
      _zsh::log success launchd "agent ${agent:t:r} unloaded"
    else
      _zsh::log error launchd "failed to unload agent ${agent:t:r}"
      rc=1
    fi
  done

  return rc
}
