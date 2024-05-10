#!/bin/zsh

function yarn() {
  case $1 in 
    create)
      # Redirect to yarnx.
      yarnx create-$@
      ;;
    fresh)
      # Upgrade global dependencies to the latest version.
      command yarn global upgrade --latest
      ;;
    init)
      # Use berry if the `-2` flag is passed.
      [[ "${@:2}" == "-2" ]] && berry init
      ;;
    up)
      # Upgrade local dependencies to the latest version.
      command yarn upgrade --latest
      ;;
    2|3|pnp)
      # Redirect to berry.
      berry ${@:2}
      ;;
    *)
      # Run classic yarn.
      command yarn $@
      ;;
  esac
}

function yarnx() {
  # Run packages in a temporary environment.
  local parts=(${(s/@/)1})
  local name="${parts[1]}"
  local version="${parts[2]}"

  if [[ ! -z "$version" ]]; then
    if [[ "$version" == "latest" ]]; then 
      local version="$(curl -s https://registry.npmjs.org/$package/latest | jq -r '.version')"
    fi
    local package="$name@$version"
  else
    local package="$name"
  fi
  
  if ! command yarn global add $package >/dev/null; then
    echo "${fg[red]}error${reset_color} Failed to install $package"
    return 1
  fi
  
  if ! $name ${@:2}; then
    echo "${fg[red]}error${reset_color} Failed to initialize $name"
    local exit_code=$?
  fi

  (command yarn global remove $name &>/dev/null &)

  return $exit_code || 0
}

function berry() {
  local berry="$(which -a yarn | grep "$HOME" | head -n 1)"

  case "$1" in
    init)
      command yarn init -2
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
