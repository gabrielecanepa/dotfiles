(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

typeset -g _profile_name_regex='^[A-Za-z[:space:],.]{2,}$'
typeset -g _profile_email_regex='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

_profile_git_editor() {
  emulate -L zsh
  case "$1" in
    code|code-insiders) print -r -- "$1 --wait --reuse-window" ;;
    atom|zed) print -r -- "$1 --wait" ;;
    mate) print -r -- 'mate -w' ;;
    subl) print -r -- 'subl -n -w' ;;
    *) print -r -- "$1" ;;
  esac
}

_profile_editor_name() {
  emulate -L zsh
  case "$1" in
    atom) print -r -- 'Atom' ;;
    code|code-insiders) print -r -- 'Visual Studio Code' ;;
    nano) print -r -- 'Nano' ;;
    subl) print -r -- 'Sublime Text' ;;
    vim) print -r -- 'Vim' ;;
    zed) print -r -- 'Zed' ;;
    *) print -r -- "$1" ;;
  esac
}

_profile_log_error() {
  emulate -L zsh
  # CR, cursor up, clear line: rewrites the prompt line in place.
  local cut=$'\r\033[1A\033[0K'

  tput civis
  print -rn -- "${cut}${fg[red]}$1${reset_color}"
  sleep 1
  print
  print -rn -- "${reset_color}${cut}> "
  tput cnorm
}

# Validated input returned in $REPLY; --allow-blank keeps the current value on empty input.
_profile_get_input() {
  emulate -L zsh
  local MATCH MBEGIN MEND match mbegin mend
  local key="$1" value
  local -i allow_blank=0
  [[ "$2" == --allow-blank ]] && allow_blank=1

  print -rn -- '> '
  read -r value

  case "$key" in
    name)
      while { (( ! allow_blank )) || [[ -n "$value" ]] } && [[ ! "$value" =~ $_profile_name_regex ]]; do
        _profile_log_error 'You must specify a valid name'
        read -r value
      done
      ;;
    email)
      while { (( ! allow_blank )) || [[ -n "$value" ]] } && [[ ! "$value" =~ $_profile_email_regex ]]; do
        if [[ -z "$value" ]]; then
          _profile_log_error 'You must specify an email'
        else
          _profile_log_error "$value is not a valid email"
        fi
        read -r value
      done
      ;;
    working_dir)
      while { (( ! allow_blank )) || [[ -n "$value" ]] } && [[ ! -d "$HOME/$value" ]]; do
        _profile_log_error "$HOME/$value is not a valid directory"
        read -r value
      done
      [[ -n "$value" ]] && value="$HOME/$value"
      ;;
    editor)
      while { (( ! allow_blank )) || [[ -n "$value" ]] } && (( ! $+commands[$value] )); do
        if [[ -z "$value" ]]; then
          _profile_log_error 'You must specify an editor'
        else
          _profile_log_error "$value not found"
        fi
        read -r value
      done
      ;;
  esac

  REPLY="$value"
}

# Rewrites only the block in ~/.zprofile preserving content outside it.
_profile_write() {
  emulate -L zsh
  local zprofile="$HOME/.zprofile"
  local marker_begin='# BEGIN PROFILE'
  local marker_end='# END PROFILE'
  local -a lines block git_config
  local key

  export GIT_EDITOR="$(_profile_git_editor "$EDITOR")"

  block=("$marker_begin")
  for key in NAME EMAIL WORKING_DIR EDITOR GIT_EDITOR; do
    block+=("export $key=\"${(P)key}\"")
  done
  block+=("$marker_end")

  if [[ -f "$zprofile" ]]; then
    local -i in_block=0
    local line
    while IFS= read -r line; do
      [[ "$line" == "$marker_begin" ]] && { in_block=1; continue }
      [[ "$line" == "$marker_end" ]] && { in_block=0; continue }
      (( in_block )) && continue
      # Drop exports that would duplicate the block.
      [[ "$line" == 'export '(NAME|EMAIL|WORKING_DIR|EDITOR|GIT_EDITOR)'='* ]] && continue
      lines+=("$line")
    done < "$zprofile"
  fi

  print -rl -- "${block[@]}" "${lines[@]}" > "$zprofile"

  git_config=(git config --global)
  [[ -n "$ZSH_GIT_CONFIG" ]] && git_config=(git config --file "$ZSH_GIT_CONFIG")
  command "${git_config[@]}" user.name "$NAME"
  command "${git_config[@]}" user.email "$EMAIL"
  command "${git_config[@]}" core.editor "$GIT_EDITOR"
}

profile() {
  emulate -L zsh
  local MATCH MBEGIN MEND match mbegin mend
  local REPLY

  local profile_cmd="${fg_bold[green]}profile${reset_color}"
  local profile_config_cmd="${profile_cmd}${fg_bold[green]} config${reset_color}"
  local profile_install_cmd="${profile_cmd}${fg_bold[green]} install${reset_color}"
  local working_dir_name="${WORKING_DIR/$HOME\//}"
  local separator="${ZSH_PROFILE_SEPARATOR:-    }"

  case "$1" in
    config)
      local -i changed_keys=0 stale_aliases=0
      local -i is_installation=0 is_reload=0
      [[ "$2" == install ]] && is_installation=1
      [[ "$2" == reload ]] && is_reload=1

      local name_msg="Name ($( (( is_installation )) && print -n 'no accent or special characters' || print -rn -- "$NAME"))"
      local email_msg="Email ($( (( is_installation )) && print -n 'to sign your commits' || print -rn -- "$EMAIL"))"
      local working_dir_msg="Working directory ($( (( is_installation )) && print -n "relative to $HOME, e.g. Developer" || print -rn -- "$working_dir_name"))"
      local editor_msg="Editor ($( (( is_installation )) && print -n 'shell command, e.g. code, nano, vim' || print -rn -- "$EDITOR"))"

      if (( ! is_installation )); then
        profile check || return 1
      fi

      if (( ! is_reload )); then
        print -r -- "${fg_bold[blue]}👤 $USER${reset_color}"
        (( is_installation )) || print -r -- '(hit ⏎ if unchanged)'
        print

        local key tmp_key msg_var
        for key in NAME EMAIL WORKING_DIR EDITOR; do
          tmp_key="${(L)key}"
          msg_var="${tmp_key}_msg"

          print -r -- "${(P)msg_var}"
          if (( is_installation )); then
            _profile_get_input "$tmp_key"
          else
            _profile_get_input "$tmp_key" --allow-blank
          fi

          if [[ -n "$REPLY" && "$REPLY" != "${(P)key}" ]]; then
            export "$key=$REPLY"
            (( changed_keys++ ))
            # The .aliases file expands these variables at source time, their shortcuts stay stale until the next shell.
            [[ "$key" == (WORKING_DIR|EDITOR) ]] && stale_aliases=1
          fi
        done
      fi

      if (( changed_keys > 0 || is_installation || is_reload )); then
        _profile_write
      else
        return 0
      fi

      if (( is_reload )); then
        print -r -- "${fg_bold[blue]}$USER${reset_color}'s profile reloaded and ready for use."
      else
        print
        print -r -- "${fg_bold[blue]}$USER${reset_color}'s profile successfully configured."
      fi

      if (( is_installation )); then
        print -r -- "Type $profile_cmd to print your current configuration or $profile_config_cmd to modify it."
      fi

      if (( stale_aliases || is_installation )); then
        print -r -- "Run ${fg[cyan]}exec zsh${reset_color} to update the aliases built from your profile."
      fi
      return 0
      ;;

    install|i)
      if profile check >/dev/null 2>&1; then
        _zsh::log warn profile "a profile is already installed for the user $USER"
        print -rn -- 'Do you want to override the current profile? (y/N) '
        local choice
        read -r choice
        if [[ "$choice" == [yY] ]]; then
          print
          profile config install
        fi
      else
        profile config install
      fi
      return $?
      ;;

    reload)
      profile config reload
      return $?
      ;;

    check)
      if [[ ! -f "$HOME/.zprofile" ]]; then
        _zsh::log error profile "missing profile for user $USER"
        print -ru2 -- "Type $profile_install_cmd to install a new profile"
        return 1
      elif [[ -z "$NAME" || ! "$NAME" =~ $_profile_name_regex ]] \
        || [[ -z "$EMAIL" || ! "$EMAIL" =~ $_profile_email_regex ]] \
        || [[ -z "$WORKING_DIR" || ! -d "$WORKING_DIR" ]] \
        || [[ -z "$EDITOR" ]] || (( ! $+commands[$EDITOR] )); then
        _zsh::log warn profile "a profile is not installed for user $USER"
        print -ru2 -- "Type $profile_install_cmd to add a new profile"
        return 1
      fi
      return 0
      ;;

    help|-h|--help)
      print -r -- 'Usage: profile <command>'
      print
      print -r -- 'Commands:'
      print -r -- '    config      Edit the current profile.'
      print -r -- '    install     Install a new profile.'
      print -r -- '    reload      Reload the current profile.'
      print -r -- '    check       Check if the current profile is installed correctly.'
      print -r -- '    help        Show this message.'
      return 0
      ;;

    *)
      if [[ -n "$1" ]]; then
        _zsh::log error profile "unknown command: $1"
        profile help
        return 1
      fi

      profile check || return 1

      local -a editor_lines
      editor_lines=("${(@f)EDITOR}")
      local editor
      editor="$(_profile_editor_name "${editor_lines[1]%% *}")"

      print -P "%Buser  %b${separator}$USER"
      print -P "%Bname  %b${separator}$NAME"
      print -P "%Bemail %b${separator}$EMAIL"
      print -P "%Bpath  %b${separator}~/$working_dir_name"
      print -P "%Beditor%b${separator}$editor"
      return 0
      ;;
  esac
}
