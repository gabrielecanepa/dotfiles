(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

_dotfiles_encoding_ok() {
  emulate -L zsh
  [[ -e "$HOME/.CFUserTextEncoding" ]]
}

_dotfiles_hushlogin_ok() {
  emulate -L zsh
  [[ -e "$HOME/.hushlogin" ]]
}

_dotfiles_git_hooks_ok() {
  emulate -L zsh
  [[ "$(command git -C "$HOME" config --local --get core.hooksPath 2>/dev/null)" == ".config/git/hooks" ]]
}

_dotfiles_vscode_ok() {
  emulate -L zsh
  local live="$1" tracked="$2"
  [[ $OSTYPE != darwin* ]] && return 0
  [[ ! -e "$live" ]] && return 0
  [[ "$live" -ef "$tracked" ]]
}

_dotfiles_launchd_disabled() {
  emulate -L zsh
  setopt local_options extended_glob
  [[ "$(<"$1")" == *'<key>Disabled</key>'[[:space:]]#'<true/>'* ]]
}

_dotfiles_launchd_render() {
  emulate -L zsh
  [[ -f "$1" ]] || return 1
  REPLY="$(<"$1")"
  REPLY="${REPLY//\$HOMEBREW_PREFIX/${HOMEBREW_PREFIX:-/opt/homebrew}}"
  REPLY="${REPLY//\$HOME/$HOME}"
}

_dotfiles_launchd_unload() {
  emulate -L zsh
  command launchctl bootout "gui/$UID/$1" 2>/dev/null
  local tries=0
  while (( tries++ < 30 )) && command launchctl print "gui/$UID/$1" &>/dev/null; do
    command sleep 0.1
  done
}

_dotfiles_launchd_stale() {
  emulate -L zsh
  local dir="$HOME/.config/launchd" agents="$HOME/Library/LaunchAgents"
  [[ $OSTYPE == darwin* && -d "$dir" ]] || return 0
  local template target REPLY
  for template in "$dir"/*.plist(N); do
    _dotfiles_launchd_disabled "$template" && continue
    target="$agents/${template:t}"
    [[ -f "$target" ]] && _dotfiles_launchd_render "$template" &&
      [[ "$REPLY" == "$(<"$target")" ]] &&
      command launchctl list "${template:t:r}" &>/dev/null && continue
    print -r -- "$template"
  done
  return 0
}

_dotfiles_launchd_retired() {
  emulate -L zsh
  local dir="$HOME/.config/launchd" agents="$HOME/Library/LaunchAgents"
  [[ $OSTYPE == darwin* && -d "$dir" ]] || return 0
  local template
  for template in "$dir"/*.plist(N); do
    _dotfiles_launchd_disabled "$template" || continue
    [[ -f "$agents/${template:t}" ]] && print -r -- "$agents/${template:t}"
  done
  return 0
}

_dotfiles_vscode_extensions() {
  emulate -L zsh
  local file="$HOME/.vscode/extensions.json" dir="$HOME/.vscode/extensions"
  [[ -f "$file" ]] || return 0
  local -a ids hits
  ids=(${(f)"$(command grep -oE '"[A-Za-z0-9-]+\.[A-Za-z0-9._-]+"' "$file")"})
  ids=(${(L)ids//\"/})
  local id
  for id in $ids; do
    hits=("$dir"/"$id"-*(N/))
    (( $#hits )) || print -r -- "$id"
  done
  return 0
}

dotfiles() {
  emulate -L zsh

  local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
  local vscode_tracked="$HOME/.vscode/user/settings.json"

  case "$1" in
    init|"")
      integer rc=0 verbose=0
      [[ "$2" == (-v|--verbose) ]] && verbose=1

      if _dotfiles_git_hooks_ok; then
        (( verbose )) && _zsh::log info dotfiles "git hooks path already set"
      elif command git -C "$HOME" config --local core.hooksPath .config/git/hooks; then
        (( verbose )) && _zsh::log success dotfiles "git hooks path set to .config/git/hooks"
      else
        _zsh::log error dotfiles "failed to set git hooks path"
        rc=1
      fi

      if _dotfiles_hushlogin_ok; then
        (( verbose )) && _zsh::log info dotfiles "login banner already silenced"
      elif command touch "$HOME/.hushlogin"; then
        (( verbose )) && _zsh::log success dotfiles "login banner silenced via ~/.hushlogin"
      else
        _zsh::log error dotfiles "failed to create ~/.hushlogin"
        rc=1
      fi

      if [[ $OSTYPE == darwin* ]]; then
        if _dotfiles_encoding_ok; then
          (( verbose )) && _zsh::log info dotfiles "text encoding already pinned"
        elif print -r -- '0x0:0x0' > "$HOME/.CFUserTextEncoding"; then
          (( verbose )) && _zsh::log success dotfiles "text encoding pinned via ~/.CFUserTextEncoding"
        else
          _zsh::log error dotfiles "failed to create ~/.CFUserTextEncoding"
          rc=1
        fi
      fi

      if [[ $OSTYPE != darwin* ]]; then
        return rc
      elif _dotfiles_vscode_ok "$vscode_settings" "$vscode_tracked"; then
        (( verbose )) && _zsh::log info dotfiles "VS Code settings symlink intact"
      elif [[ ! -e "$vscode_tracked" ]]; then
        _zsh::log warn dotfiles "tracked VS Code settings missing at $vscode_tracked"
      elif command ln -sf "$vscode_tracked" "$vscode_settings"; then
        (( verbose )) && _zsh::log success dotfiles "VS Code settings re-linked"
      else
        _zsh::log error dotfiles "failed to re-link VS Code settings"
        rc=1
      fi

      if [[ -n "$OBSIDIAN_VAULT" ]]; then
        local vault_target="$(_dotfiles_vault_target)"
        if [[ -z "$vault_target" ]]; then
          _zsh::log warn dotfiles "can't find an Obsidian vault named $OBSIDIAN_VAULT"
        elif [[ "$vault" -ef "$vault_target" ]]; then
          (( verbose )) && _zsh::log info dotfiles "~/.vault symlink intact"
        elif [[ -e "$vault" && ! -L "$vault" ]]; then
          _zsh::log warn dotfiles "~/.vault already exists and is not a symlink"
        elif command ln -sfn "$vault_target" "$vault"; then
          _zsh::log success dotfiles "~/.vault linked to $fg[cyan]$OBSIDIAN_VAULT$reset_color"
        else
          _zsh::log error dotfiles "failed to link ~/.vault to $fg[cyan]$OBSIDIAN_VAULT$reset_color"
          rc=1
        fi
      fi

      local -a stale
      stale=(${(f)"$(_dotfiles_launchd_stale)"})
      if (( $#stale == 0 )); then
        (( verbose )) && _zsh::log info dotfiles "launch agents generated"
      elif ! command mkdir -p "$HOME/Library/LaunchAgents"; then
        _zsh::log error dotfiles "failed to create ~/Library/LaunchAgents"
        rc=1
      else
        local template target label REPLY
        for template in $stale; do
          target="$HOME/Library/LaunchAgents/${template:t}"
          label="${template:t:r}"
          command rm -f -- "$target"
          if ! { _dotfiles_launchd_render "$template" && print -r -- "$REPLY" > "$target" }; then
            _zsh::log error dotfiles "failed to generate launch agent $label"
            rc=1
            continue
          fi
          _dotfiles_launchd_unload "$label"
          if command launchctl bootstrap "gui/$UID" "$target" 2>/dev/null; then
            _zsh::log success dotfiles "launch agent $label generated"
          else
            _zsh::log warn dotfiles "launch agent $label generated but unloaded"
          fi
        done
      fi

      local -a retired
      retired=(${(f)"$(_dotfiles_launchd_retired)"})
      local agent
      for agent in $retired; do
        _dotfiles_launchd_unload "${agent:t:r}"
        if command rm -f -- "$agent"; then
          _zsh::log success dotfiles "launch agent ${agent:t:r} disabled"
        else
          _zsh::log error dotfiles "failed to disable launch agent ${agent:t:r}"
          rc=1
        fi
      done

      local -a extensions
      extensions=(${(f)"$(_dotfiles_vscode_extensions)"})
      if (( $#extensions == 0 )); then
        (( verbose )) && _zsh::log info dotfiles "VS Code extensions synced"
      elif ! (( $+commands[code] )); then
        _zsh::log warn dotfiles "code CLI not found, skipping $#extensions missing extension(s)"
      else
        local extension
        for extension in $extensions; do
          if command code --install-extension "$extension" >/dev/null 2>&1; then
            _zsh::log success dotfiles "VS Code extension $extension installed"
          else
            _zsh::log warn dotfiles "failed to install VS Code extension $extension"
          fi
        done
      fi

      if (( $+functions[_npm_global_drift] )); then
        local -a npm_drift npm_missing npm_drifted npm_untracked
        npm_drift=(${(f)"$(_npm_global_drift)"})
        npm_missing=(${${(M)npm_drift:#missing *}#missing })
        npm_drifted=(${${(M)npm_drift:#drifted *}#drifted })
        npm_untracked=(${${(M)npm_drift:#untracked *}#untracked })
        if (( $#npm_drift == 0 )); then
          (( verbose )) && _zsh::log info dotfiles "npm globals synced"
        else
          if (( $#npm_missing )); then
            if command npm install --global "${npm_missing[@]}" >/dev/null 2>&1; then
              _zsh::log success dotfiles "npm globals installed ${(j:, :)npm_missing}"
            else
              _zsh::log error dotfiles "failed to install npm globals ${(j:, :)npm_missing}"
              rc=1
            fi
          fi
          (( $#npm_drifted )) &&
            _zsh::log warn dotfiles "npm globals drifted, run 'npm dump' to capture: ${(j:, :)npm_drifted}"
          (( $#npm_untracked )) &&
            _zsh::log warn dotfiles "untracked npm globals, run 'npm dump' to track: ${(j:, :)npm_untracked}"
        fi
      fi

      return rc
      ;;
    doctor)
      integer drift=0
      if _dotfiles_git_hooks_ok; then
        _zsh::log success dotfiles "git hooks path OK"
      else
        _zsh::log error dotfiles "git hooks path is NOT .config/git/hooks"
        drift=1
      fi
      if _dotfiles_hushlogin_ok; then
        _zsh::log success dotfiles "hushlogin OK"
      else
        _zsh::log error dotfiles "~/.hushlogin missing"
        drift=1
      fi
      if [[ $OSTYPE == darwin* ]]; then
        if _dotfiles_encoding_ok; then
          _zsh::log success dotfiles "text encoding OK"
        else
          _zsh::log error dotfiles "~/.CFUserTextEncoding missing"
          drift=1
        fi
        if _dotfiles_vscode_ok "$vscode_settings" "$vscode_tracked"; then
          _zsh::log success dotfiles "VS Code settings symlink OK"
        else
          _zsh::log error dotfiles "VS Code settings is not a symlink to the tracked file"
          drift=1
        fi
        local -a stale_agents retired_agents
        stale_agents=(${(f)"$(_dotfiles_launchd_stale)"})
        retired_agents=(${(f)"$(_dotfiles_launchd_retired)"})
        if (( $#stale_agents == 0 && $#retired_agents == 0 )); then
          _zsh::log success dotfiles "launch agents OK"
        fi
        if (( $#stale_agents )); then
          _zsh::log error dotfiles "launch agents out of sync: ${(j:, :)${(@)stale_agents:t:r}}"
          drift=1
        fi
        if (( $#retired_agents )); then
          _zsh::log error dotfiles "disabled launch agents still installed: ${(j:, :)${(@)retired_agents:t:r}}"
          drift=1
        fi
        local -a missing_extensions
        missing_extensions=(${(f)"$(_dotfiles_vscode_extensions)"})
        if (( $#missing_extensions == 0 )); then
          _zsh::log success dotfiles "VS Code extensions OK"
        else
          _zsh::log error dotfiles "missing VS Code extensions: ${(j:, :)missing_extensions}"
          drift=1
        fi
      fi
      if (( $+functions[_npm_global_drift] )); then
        local -a npm_drift
        npm_drift=(${(f)"$(_npm_global_drift)"})
        if (( $#npm_drift == 0 )); then
          _zsh::log success dotfiles "npm globals OK"
        else
          _zsh::log error dotfiles "npm globals out of sync: ${(j:, :)npm_drift}"
          drift=1
        fi
      fi
      (( drift == 0 )) && _zsh::log info dotfiles "no drift detected"
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
