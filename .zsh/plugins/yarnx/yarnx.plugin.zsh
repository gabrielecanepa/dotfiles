#!/bin/zsh

function yarn() {
  case $1 in 
    create)
      # Run package in a temporary environment.
      local package="create-$2"
      local installed=false

      /opt/homebrew/bin/yarn global add $package &>/dev/null &&
      installed=true &&
      $package ${@:3}
      
      local exit_code=$?

      if [[ $installed ]]; then
        (/opt/homebrew/bin/yarn global remove $package &>/dev/null &)
      fi

      return $exit_code
      ;;
    fresh)
      # Upgrade global dependencies.
      /opt/homebrew/bin/yarn global upgrade $(cat ~/.yarn/package.json | jq -r '.dependencies | keys | .[]' | tr '\n' ' ')
      return $?
      ;;
    init)
      # Use berry when the `-2` flag is passed.
      if [[ "${@:2}" == "-2" ]]; then
        berry init
        return $?
      fi
      ;;
    2|3|pnp)
      # Redirect to berry.
      berry ${@:2}
      return $?
      ;;
  esac
  
  # Run classic yarn.
  /opt/homebrew/bin/yarn $@
}

function berry() {
  local berry="$(which -a yarn | grep "$HOME" | head -n 1)"

  case "$1" in
    init)
      /opt/homebrew/bin/yarn init -2
      local exit_code=$?

      $berry add >/dev/null

      # Custom editorconfig.
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
      node -v &>/dev/null && echo ${$(node -v)#v} > .node-version

      # Reinitialize Git.
      rm -rf .git && git init >/dev/null

      return $exit_code
      ;;
    *)
      $berry $@
      ;;
  esac
}

alias yarn2="berry"
alias yarnpnp="berry"
