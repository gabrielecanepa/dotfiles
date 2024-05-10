#!/bin/sh

function env-latest() {
  local version_manager=$1
  local version_managers=(rbenv pyenv)

  # Check the specified version manager.
  if [[ -z "$version_manager" ]] || ! command -v $version_manager >/dev/null || ! [[ " ${version_managers[@]} " =~ " ${version_manager} " ]]; then
    echo "${fg[red]}Error: you must specify a supported version manager$reset_color"
    return 1
  fi

  local args=${@:2}
  local versions=$($version_manager install --list | sed 's/^[ \t]*//;s/[ \t]*$//')

  if [[ -z "$args" ]]; then
    echo $versions | grep -vi "[A-Za-z\-]" | tail -1
  else
    echo $versions | grep "^$args" | tail -1
  fi
}

function rbenv-latest() {
  env-latest rbenv $@
}
function pyenv-latest() {
  env-latest pyenv $@
}
