#!/bin/zsh

function yarn() {
  case $1 in 
    init)
      if [[ "${@:2}" == "-2" ]]; then
        berry init
        return $?
      fi
      ;;
    pnp)
      berry ${@:2}
      return $?
      ;;
  esac
  
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
