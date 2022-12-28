#!/bin/zsh

function macprefs () {
  if ! python --version 2>&1 | grep -q "Python 2\."; then
    echo "${fg[red]}Error$reset_color You must use Python 2 to run this script."
    return 1
  fi

  case "$1" in
    backup|restore)
      local dir
      for dir in $MACPREFS_BACKUP_DIRS; do
        echo "Backing up to $dir"
        sudo MACPREFS_BACKUP_DIR="$dir" command macprefs $@
      done
      ;;
    *)
      command macprefs $@
      ;;
  esac
}
