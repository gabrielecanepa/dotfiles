#!/bin/zsh

##
# Profile plugin for Zsh
# This plugin allows you to manage your Zsh profile, including setting up your name, email, working directory, and editor.
# It provides commands to install, reload, and check the profile configuration.
#
# Usage
#   profile                 # Print the current profile
#   profile install|i       # Install a new profile
#   profile config          # Configure the profile
#   profile reload          # Reload the current profile
#   profile check           # Check if the profile is installed correctly
#   profile help|-h|--help  # Print help message
#
# Options
#   PROFILE_SEPARATOR: sets a custom separator for the profile output

## 
# Prints the current profile or executes a command among `config`, `install`, `reload`, `check`, or `help`.
#
function profile() (
  local CUT="\r\033[1A\033[0K"
  local PROFILE_CMD="${fg_bold[green]}profile${reset_color}"
  local PROFILE_CONFIG_CMD="$PROFILE_CONFIG_CMD${fg_bold[green]} config${reset_color}"
  local PROFILE_INSTALL_CMD="$PROFILE_CMD${fg_bold[green]} install${reset_color}"
  local WORKING_DIR_NAME=${WORKING_DIR/\/Users\/$USER\//}
  local NAME_REGEX="[A-Za-z\s,\.]{2,}"
  local EMAIL_REGEX="[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}"
  local SEPARATOR=" | "

  [[ -n "$PROFILE_SEPARATOR" ]] && SEPARATOR=$PROFILE_SEPARATOR

  ## 
  # Converts the editor CLI command into the corresponding Git command.
  # get_git_editor <command>
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
  # Converts the editor CLI command into the corresponding application name.
  # get_editor_name <command>
  #
  local function get_editor_name() {
    case $1 in
      atom)
        echo "Atom"
        ;;
      code|code-insiders)
        echo "Visual Studio Code"
        ;;
      nano)
        echo "Nano"
        ;;
      subl)
        echo "Sublime Text"
        ;;
      vim)
        echo "Vim"
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
    tput civis
    echo "${CUT}${fg[red]}$1\c${reset_color}"
    sleep 1
    echo
    echo -n "${reset_color}${CUT}> "
    tput cnorm
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
            log_error "$editor not found"
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

      ! $is_installation && ! profile check && return 1

      if ! $is_reload; then
        echo "${fg_bold[blue]}👤 $USER${reset_color}"
        ! $is_installation && echo "(hit ⏎ if unchanged)"
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

    install|i)
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
        echo "⚠️  A profile is not installed for user $USER"
        echo "Type $PROFILE_INSTALL_CMD to add a new profile"
        return 1
      fi
      ;;

    help|-h|--help)
      echo "Usage: profile <command>"
      echo
      echo "Commands:"
      echo -e "  config          Edit the current profile"
      echo -e "  install|i       Install a new profile"
      echo -e "  reload          Reload the current profile"
      echo -e "  check           Check if the current profile is installed correctly"
      echo -e "  help|-h|--help  Print this help message"
      ;;

    *)
      if [[ ! -z $1 ]]; then
        echo "${fg[red]}Unknown command: $1${reset_color}"
        profile help
      else
        local editor=$(get_editor_name $(echo $EDITOR | head -n1 | cut -d " " -f1))

        if profile check; then
          print -P "%F{039}user  $SEPARATOR%{$reset_color%}$USER"
          print -P "%F{039}name  $SEPARATOR%{$reset_color%}$NAME"
          print -P "%F{039}email $SEPARATOR%{$reset_color%}$EMAIL"
          print -P "%F{039}path  $SEPARATOR%{$reset_color%}~/$WORKING_DIR_NAME"
          print -P "%F{039}editor$SEPARATOR%{$reset_color%}$editor"
        else
          return 1
        fi
      fi
      ;;
  esac
)
