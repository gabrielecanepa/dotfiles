#!/bin/zsh

function yarn() {
  case $1 in 
    create)
      # Run package in a temporary environment.
      local package="create-$2"
      echo "${fg[blue]}info${reset_color} Fetching $package..."
      /opt/homebrew/bin/yarn global add $package &>/dev/null &&
      $package ${@:3} &&
      echo "${fg[blue]}info${reset_color} Removing $package..." &&
      /opt/homebrew/bin/yarn global remove $package &>/dev/null &&
      echo "${fg[green]}success${reset_color} Done!" &&
      cd $3
      return $?
      ;;
    fresh)
      yarn global upgrade
      return $?
      ;;
    init)
      # Use berry if the -2 arg is passed.
      if [[ "${@:2}" == "-2" ]]; then
        berry init
        return $?
      fi
      ;;
    pnp)
      # Redirect to berry.
      berry ${@:2}
      return $?
      ;;
  esac
  
  # Run classic yarn.
  /opt/homebrew/bin/yarn $@
}

function berry() {
  local berry=$(which -a yarn | grep "$HOME" | head -n 1)

  case "$1" in
    init)
      /opt/homebrew/bin/yarn init -2
      local exit_code=$?

      $berry add >/dev/null

      # Adjust editorconfig.
      if [[ -f ~/.editorconfig ]]; then
        rm -rf .editorconfig
        touch .editorconfig
        echo "root = true\n" >> .editorconfig
        echo "$(cat ~/.editorconfig)" >> .editorconfig
      fi

      # Add yarn folder and pnp files to gitignore.
      rm -rf .gitattributes .gitignore
      echo ".yarn/" >> .gitignore
      echo ".pnp.*" >> .gitignore

      # Add current node version.
      if node -v &>/dev/null; then 
        echo ${$(node -v)#v} > .node-version
      fi

      # reinitialize git
      rm -rf .git && git init >/dev/null

      return $exit_code
      ;;
    *)
      $berry $@
      ;;
  esac
}

alias yarnpnp="berry"
