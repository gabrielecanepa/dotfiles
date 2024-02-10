#!/bin/zsh

function yarn1() {
  # Return if yarn is in local environment.
  if [[ $(which -a yarn) == *"node_modules"* ]]; then
    command yarn $@
    return $?
  fi

  local dir="$(pwd)"
  cd $dir

  local version=$(command yarn -v)

  if [[ $version != "1."* ]]; then 
    command yarn policies set-version "$(npm view yarn version)" >/dev/null
  fi

  case $1 in 
    create)
      # Redirect to yarnx.
      yarnx create-$@
      ;;
    fresh)
      # Upgrade global dependencies to the latest version.
      NODE_OPTIONS="--no-deprecation" command yarn global upgrade --latest
      ;;
    init)
      # Use berry if `-2` is specified.
      [[ "${@:2}" == "-2" ]] && berry init
      ;;
    latest)
      # Upgrade local dependencies to the latest version.
      NODE_OPTIONS="--no-deprecation" command yarn upgrade --latest
      ;;
    2|3|pnp)
      # Redirect to berry.
      berry ${@:2}
      ;;
    *)
      # Run classic yarn.
      NODE_OPTIONS="--no-deprecation" command yarn $@
      ;;
  esac

  exit=$?
  [[ $version != "1."* ]] && command yarn policies set-version $version >/dev/null
  cd $dir
  return $exit
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
