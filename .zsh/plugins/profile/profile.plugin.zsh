#!/bin/zsh

CUT="\r\033[1A\033[0K"

PROFILE_CMD="${fg[green]}profile$reset_color"
PROFILE_CONFIG_CMD="$PROFILE_CMD ${fg_bold}config$reset_color"
PROFILE_INSTALL_CMD="$PROFILE_CMD ${fg_bold}install$reset_color"

NAME_REGEX="[A-Za-z\s,\.]{2,}"
EMAIL_REGEX="[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}"

WORKING_DIR_NAME=${WORKING_DIR##*/}

# Available editors:
EDITORS=(
  "atom"     # Atom
  "brackets" # Brackets
  "emacs"    # Emacs
  "coda"     # Coda
  "code"     # Visual Studio Code
  "mate"     # TextMate
  "subl"     # Sublime Text
  "vim"      # Vim
)
case $EDITOR in # convert editors name
  code)
    EDITOR_NAME="Visual Studio Code"
    ;;
  mate)
    EDITOR_NAME="Text Mate"
    ;;
  subl)
    EDITOR_NAME="Sublime Text"
    ;;
  *)
    EDITOR_NAME="${(C)EDITOR}"
    ;;
esac

# TODO: check for updates

# get-input <input> [--allow-blank]
# Read, validate, and store an input
get-input () {
  allow_blank=$([ "$2" = --allow-blank ] && echo true || echo false)

  log-input-error () {
    tput civis # hide cursor
    echo "${CUT}${fg[red]}$1\c$reset_color"
    sleep 1
    echo
    echo -n "${CUT}> "
    tput cnorm # show cursor
  }

  echo "> "
  read -r $1

  case $1 in
    name)
      while [ $allow_blank = false ] || [ "$name" ] && ! [[ "$name" =~ $NAME_REGEX ]]; do
        log-input-error "You must specify a valid name"
        read -r name
      done
      ;;
    email)
      while [ $allow_blank = false ] || [ "$email" ] && [[ ! "$email" =~ $EMAIL_REGEX ]]; do
        if [ "$email" ]; then
          log-input-error "$email is not a valid email"
        else
          log-input-error "You must specify an email"
        fi
        read -r email
      done
      ;;
    working_dir)
      while [ $allow_blank = false ] || [ "$working_dir" ] && [ ! -d "$HOME/$working_dir/dotfiles" ]; do
        if [ -d "$HOME/$working_dir" ]; then
          log-input-error "$HOME$([ $working_dir ] && echo /$working_dir) doesn't contain any dotfiles"
        else
          log-input-error "$HOME/$working_dir is not a valid directory"
        fi
        read -r working_dir
      done
      [ "$working_dir" ] && working_dir="$HOME/$working_dir"
      ;;
    editor)
      while [ $allow_blank = false ] || [ "$editor" ] && [[ -z "${EDITORS[(r)$editor]}" ]] && ! type -a "$editor" >/dev/null; do
        if [ "$editor" ]; then
          log-input-error "$editor is not a valid command"
        else
          log-input-error "You must specify a valid command"
        fi
        read -r editor
      done
      ;;
  esac
}

# ln-dir <source> <target>
# Create symlink for all files in a directory
ln-dir () {
  source="$1"
  target_dir="$2"
  target_dir_name=$(basename "$target_dir")

  for file in "$source"/*; do
    source_name=$(basename "$file")
    [ "$source_name" = "$target_dir_name" ] && return

    target=$(readlink "$target_dir/$source_name")
    if [ ! "$target" ] || [ "$target" != "$file" ]; then
      ln -sf "$file" "$target/$source_name"
    fi
  done
}

# ln-dotfiles
# Create symlink for files in $WORKING_DIR/dotfiles
ln-dotfiles () {
  for file in "$WORKING_DIR"/dotfiles/.*; do
    filename=$(basename "$file")
    target=$(readlink "$HOME/$filename")

    if [ ! $target ] || [ "$target" != "$WORKING_DIR/dotfiles/$filename" ]; then
      case $filename in
        # Skip
        .DS_Store|.git|.github|.iterm2|README.md)
          ;;
         # Globals
        .gitconfig)
          ln -sf "$file" "$HOME/${filename}_global"
          ;;
        # Atom
        .atom)
          atom_path="$HOME/.atom"
          if [ -d $atom_path ]; then
            ln-dir $file $atom_path
          fi
          ;;
        .oh-my-zsh)
          echo "${fg[yellow]}WARNING: you are about to override all the content of your \$ZSH_CUSTOM and link it to $file$reset_color"
          echo "Are you sure you want to continue? (Y/n)"
          read -r choice
          if [[ "$choice" =~ [yY] ]]; then
            ln -sf "$file" "$HOME/$filename/custom"
          fi
          ;;
        # Sublime Text
        .subl)
          subl_path="/Users/$USER/Library/Application Support/Sublime Text 3/Packages/User"
          if [ -d $subl_path ]; then
            ln-dir $file $subl_path
          fi
          ;;
        *)
          ln -sf $file $HOME/$filename
          ;;
      esac
    fi
  done
}

# profile [check|config|install|reload|help]
# Print the current profile or execute one of the commands
profile () {
  case $1 in
    config)
      changed_keys=0
      installation=$([ "$2" = install ] && echo true || echo false)
      reload=$([ "$2" = reload ] && echo true || echo false)
      name_msg="${fg_bold}🔏 First and last name$reset_color ($([ $installation = true ] && echo 'no accent or special characters' || echo $NAME))"
      email_msg="${fg_bold}📧 Email address$reset_color ($([ $installation = true ] && echo 'to sign your commits' || echo $EMAIL))"
      working_dir_msg="${fg_bold}📁 Working directory$reset_color ($([ $installation = true ] && echo relative to $HOME, e.g. code || echo \~/$WORKING_DIR_NAME))"
      editor_msg="${fg_bold}⌨️  Text editor$reset_color ($([ $installation = true ] && echo 'shell command of the app you use, e.g. atom, subl, code, vim, etc.' || echo $EDITOR_NAME))"

      if [ $installation = false ] && ! profile check; then
        return 1
      fi

      if [ $reload = false ]; then
        echo "${fg_bold[cyan]}👤 $USER$reset_color"
        [ $installation = false ] && echo "(hit ⏎ if unchanged)"

        echo ""

        for key in NAME EMAIL WORKING_DIR EDITOR; do
          tmp_key="${(L)key}"
          eval echo $"${tmp_key}_msg"
          eval get-input $tmp_key "$([ $installation = false ] && echo --allow-blank)"
          if [ ${(P)tmp_key} ] && [ "${(P)tmp_key}" != "${(P)key}" ]; then
            export $key=${(P)tmp_key}
            changed_keys+=1
          fi
        done

        echo ""
      fi

      if [ $changed_keys -gt 0 ] || [ $reload = true ]; then
        _action=$([ $reload = true ] && echo "Reloading" || echo "Storing")
        echo "${fg[blue]}$_action profile...$reset_color"
        echo -n "" > "$HOME/.zprofile"
        for key in NAME EMAIL WORKING_DIR EDITOR; do
          echo "export $key=\"${(P)key}\"" >> "$HOME/.zprofile"
        done
        echo "${CUT}${fg[green]}$_action profile ✅$reset_color"
      else
        echo "Nothing changed"
        return 0
      fi

      echo "${fg[blue]}Linking dotfiles...$reset_color"
      if ! ln-dotfiles; then
        echo "${fg[red]}ERROR: can't link dotfiles$reset_color"
        echo "Please try again or open a new issue here: https://github.com/gabrielecanepa/dotfiles/issues/new"
        return 1
      fi
      echo "${CUT}${fg[green]}Linking dotfiles ✅$reset_color"

      echo "${fg[blue]}Configuring git...$reset_color"
      git config --global user.name "$NAME"
      git config --global user.email "$EMAIL"
      case $EDITOR in
        [Aa]tom|[Cc]ode|[Mm]ate)
          GIT_EDITOR="$EDITOR -w"
          ;;
        [Ee]macs|[Ss]ubl)
          GIT_EDITOR="$EDITOR -nw"
          ;;
        *)
          GIT_EDITOR="$EDITOR"
          ;;
      esac
      git config --global core.editor "$GIT_EDITOR"
      git config --global include.path "$HOME/.gitconfig_global"
      git config --global core.excludesfile "$HOME/.gitignore"
      echo "${CUT}${fg[green]}Configuring git ✅$reset_color"

      . "$HOME/.zshrc"

      if [ $reload = false ]; then
        echo ""
        echo "Profile successfully configured for ${fg_bold}${CYN}$USER$reset_color"
      fi

      if [ $installation = true ]; then
        echo "Type $PROFILE_CMD to print your current profile or $PROFILE_CONFIG_CMD to modify it"
      fi

      return 0
      ;;

    install)
      if profile check; then
        echo "${fg[yellow]}WARNING: you already have a profile installed for $USER$reset_color"
        echo -n "Do you want to override the current configuration? (y/N) "
        read -r choice
        [[ "$choice" =~ [yY] ]] && profile config install
      else
        profile config install
      fi
      ;;

    reload)
      profile config reload
      ;;

    check)
      if [[ ! $NAME =~ $NAME_REGEX ]] || [[ ! $EMAIL =~ $EMAIL_REGEX ]] || ([[ -n "${EDITORS[(r)$editor]}" ]] && ! type -a $editor >/dev/null) || [ ! -d $WORKING_DIR/dotfiles ]; then
        echo "${fg[red]}⚠️  Profile installed incorrectly$reset_color"
        echo "Type $PROFILE_INSTALL_CMD to install a new profile for the current user"
        exit 1
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
      if [ $1 ]; then
        echo "${fg[red]}Unknown command: $1$reset_color"
        profile help
      else
        if profile check; then
          echo "${fg_bold[cyan]}👤 $USER$reset_color"
          echo " ⌙ 📝 $NAME"
          echo " ⌙ 📧 $EMAIL"
          echo " ⌙ 📁 ~/$WORKING_DIR_NAME"
          echo " ⌙ 💻 $EDITOR_NAME"
        fi
      fi
      ;;
  esac
}
