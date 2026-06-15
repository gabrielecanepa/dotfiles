#!/bin/zsh

function plugin() {
  name="$1"
  zsh_path="$ZSH/plugins/$name/$name.plugin.zsh"
  custom_path="$ZSH_CUSTOM/plugins/$name/$name.plugin.zsh"
  [[ -f "$custom_path" ]] && zsh_path="$custom_path"

  if [[ -z "$name" || "$name" == "--help" || "$name" == "-h" ]]; then
    echo "plugin: load or reload a zsh plugin."
    echo "Usage: plugin <name>"
    return 0
  fi

  if [[ ! -f "$zsh_path" && ! -f "$custom_path" ]]; then
    echo "Plugin not found: $name"
    return 1
  fi

  . "$zsh_path"
}

function _plugin() {
  local -aU names
  local name
  for name in "$ZSH_CUSTOM/plugins"/*(/N:t); do
    [[ -f "$ZSH_CUSTOM/plugins/$name/$name.plugin.zsh" ]] && names+=("$name")
  done
  _describe -t plugins 'plugin' names
}

compdef _plugin plugin
