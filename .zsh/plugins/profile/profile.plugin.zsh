#!/bin/zsh

## 
# Prints the current profile or executes a command among `config`, `install`, `reload`, `check`, or `help`.
#
function profile() (
  local CUT="\r\033[1A\033[0K"

  local _profile_cmd="${fg[green]}profile"
  local PROFILE_CMD="${_profile_cmd}${reset_color}"
  local PROFILE_CONFIG_CMD="${_profile_cmd} config${reset_color}"
  local PROFILE_INSTALL_CMD="${_profile_cmd} install${reset_color}"

  local NAME_REGEX="[A-Za-z\s,\.]{2,}"
  local EMAIL_REGEX="[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}"

  local WORKING_DIR_NAME=${WORKING_DIR/\/Users\/$USER\//}

  local EDITORS=(
    "atom"            # Atom
    "brackets"        # Brackets
    "coda"            # Coda
    "code"            # Visual Studio Code
    "code-insiders"   # Visual Studio Code Insiders
    "emacs"           # Emacs
    "mate"            # TextMate
    "nano"            # Nano
    "subl"            # Sublime Text
    "vim"             # Vim
  )

  ## 
  # Converts the CLI name of an editor into the application name.
  # get_editor_name <editor>
  #
  local function get_editor_name() {
    case $1 in
      code)
        echo "Visual Studio Code"
        ;;
      code-insiders)
        echo "Visual Studio Code Insiders"
        ;;
      mate)
        echo "Text Mate"
        ;;
      subl)
        echo "Sublime Text"
        ;;
      *)
        echo $1
        ;;
    esac
  }

  ## 
  # Converts the editor CLI command into the corresponding Git command.
  # get_git_editor <editor>
  #
  local function get_git_editor() {
    case $1 in
      atom|code|code-insiders)
        echo "$1 --wait"
        ;;
      mate)
        echo "mate -w"
        ;;
      subl)
        echo "subl -n -w"
        ;;
      *)
        echo $1
        ;;
    esac
  }

  ##
  # Logs the specified error message.
  # log_error <message>
  #
  local function log_error() {
    tput civis # hide cursor
    echo "${CUT}${fg[red]}$1\c${reset_color}"
    sleep 1
    echo
    echo -n "${reset_color}${CUT}> "
    tput cnorm # show cursor
  }

  ## 
  # Reads, validates, and stores an input.
  # get_input <input> [--allow-blank]
  #
  local function get_input() {
    local allow_blank=$([[ "$2" == --allow-blank ]] && echo true || echo false)

    printf "> "
    read -r $1

    case $1 in
      name)
        while ! $allow_blank || [[ ! -z "$name" ]] && ! [[ "$name" =~ $NAME_REGEX ]]; do
          log_error "You must specify a valid name"
          read -r name
        done
        ;;
      email)
        while ! $allow_blank || [[ ! -z "$email" ]] && [[ ! "$email" =~ $EMAIL_REGEX ]]; do
          if [[ -z "$email" ]]; then
            log_error "You must specify an email"
          else
            log_error "$email is not a valid email"
          fi
          read -r email
        done
        ;;
      working_dir)
        while ! $allow_blank || [[ ! -z "$working_dir" ]] && [[ ! -d "$HOME/$working_dir" ]]; do
          log_error "$HOME/$working_dir is not a valid directory"
          read -r working_dir
        done
        [[ ! -z "$working_dir" ]] && working_dir="$HOME/$working_dir"
        ;;
      editor)
        while ! $allow_blank || [[ ! -z "$editor" ]] && ! type -a "$editor" >/dev/null; do
          if [[ -z "$editor" ]]; then
            log_error "You must specify an editor"
          else
            local editor_name=$(get_editor_name "$editor")

            if [[ -z "$editor_name" ]]; then
              log_error "$editor is not a valid command"
            else
              log_error "$editor_name not found"
            fi
          fi
          read -r editor
        done
        ;;
    esac
  }

  case $1 in
    config)
      local changed_keys=0
      local is_installation=$([[ "$2" == install ]] && echo true || echo false)
      local is_reload=$([[ "$2" == reload ]] && echo true || echo false)
      local name_msg="Name ($($is_installation && echo 'no accent or special characters' || echo $NAME))"
      local email_msg="Email ($($is_installation && echo 'to sign your commits' || echo $EMAIL))"
      local working_dir_msg="Working directory ($($is_installation && echo "relative to $HOME, e.g. Developer" || echo $WORKING_DIR_NAME))"
      local editor_msg="Editor ($($is_installation && echo "shell command, e.g. code, nano, vim" || echo $EDITOR))"

      if ! $is_installation && ! profile check; then
        return 1
      fi

      if ! $is_reload; then
        echo "${fg_bold[blue]}👤 $USER${reset_color}"

        if ! $is_installation; then
          echo "(hit ⏎ if unchanged)"
        fi

        echo ""

        for key in NAME EMAIL WORKING_DIR EDITOR; do
          local tmp_key="${(L)key}"

          eval echo $"${tmp_key}_msg"
          eval get_input $tmp_key$(! $is_installation && echo " --allow-blank")

          if [[ ! -z "${(P)tmp_key}" ]] && [[ "${(P)tmp_key}" != "${(P)key}" ]]; then
            export $key="${(P)tmp_key}"
            changed_keys+=1
          fi
        done
        key=
      fi

      if [[ $changed_keys > 0 ]] || $is_installation || $is_reload; then
        echo -n "" > "$HOME/.zprofile"
        for key in NAME EMAIL WORKING_DIR EDITOR; do
          echo "export $key=\"${(P)key}\"" >> "$HOME/.zprofile"
        done
        echo "export GIT_EDITOR=\"$(get_git_editor $EDITOR)\"" >> "$HOME/.zprofile"
      else
        return 0
      fi

      if $is_reload; then
        echo "${fg_bold[blue]}$USER${reset_color}'s profile reloaded and ready for use."
      else
        echo "\n${fg_bold[blue]}$USER${reset_color}'s profile successfully configured."
      fi

      if $is_installation; then
        echo "Type $PROFILE_CMD to print your current configuration or $PROFILE_CONFIG_CMD to modify it."
      fi

      exec zsh --login
      ;;

    install)
      if profile check >/dev/null; then
        echo "${fg[yellow]}WARNING: you already have a profile installed for the user $USER${reset_color}"
        echo -n "Do you want to override the current profile? (y/N) "
        read -r choice
        if [[ "$choice" =~ [yY] ]]; then
          echo ""
          profile config install
        fi
      else
        profile config install
      fi
      ;;

    reload)
      profile config reload
      ;;

    check)
      if [[ -z "$HOME/.profile" || -z "$HOME/.zprofile" ]]; then
        echo "${fg[red]}Missing profile for user $USER${reset_color}"
        echo "Type $PROFILE_INSTALL_CMD to install a new profile"
        return 1
      elif [[ -z "$NAME" ]] || [[ ! "$NAME" =~ $NAME_REGEX ]] || [[ -z "$EMAIL" ]] || [[ ! "$EMAIL" =~ $EMAIL_REGEX ]] || [[ -z "$WORKING_DIR" ]] || [[ ! -d "$WORKING_DIR" ]] || [[ -z "$EDITOR" ]] || ! type -a "$EDITOR" >/dev/null; then
        echo "${fg[red]}⚠️  Incorrect profile for user $USER${reset_color}"
        echo "Type $PROFILE_INSTALL_CMD to install a new profile"
        return 1
      fi
      ;;

    help|-h|--help)
      echo "Usage: profile [command]"
      echo
      echo "Commands:"
      echo -e "  config\t Edit the current profile"
      echo -e "  install\t Install a new profile"
      echo -e "  reload\t Reload the current profile"
      echo -e "  check\t\t Check if the current profile is installed correctly"
      echo -e "  help\t\t Print this help message"
      ;;

    *)
      if [[ ! -z $1 ]]; then
        echo "${fg[red]}Unknown command: $1${reset_color}"
        profile help
      else
        if profile check; then
          print -P "${fg_bold[blue]}👤 $USER${reset_color}"
          print -P "%F{015}Name:${reset_color} $NAME"
          print -P "%F{015}Email:${reset_color} $EMAIL"
          print -P "%F{015}Working directory:${reset_color} $WORKING_DIR"
          print -P "%F{015}Editor:${reset_color} $(get_editor_name $EDITOR)"
        else
          return 1
        fi
      fi
      ;;
  esac
)
