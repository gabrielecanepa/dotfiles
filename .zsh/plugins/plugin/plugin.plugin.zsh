#!/bin/zsh

# Dinamically load a Zsh plugin.
# Usage: plugin <name> [args]

function plugin() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "plugin: load or reload a zsh plugin."
    echo "Usage: plugin <name> [args]"
    return 0
  fi

  local args="$2"
  local plugin_path="$ZSH/plugins/$name/$name.plugin.zsh"
  local user_plugin_path="$ZSH_CUSTOM/plugins/$name/$name.plugin.zsh"

  if [[ ! -f "$plugin_path" && ! -f "$user_plugin_path" ]]; then
    echo "Plugin not found: $name"
    return 1
  fi

  if [[ -f "$user_plugin_path" ]]; then
    local plugin_path="$user_plugin_path"
  fi

  . "$plugin_path" $args
}

for _plugin in $lazy_plugins; do
  function $_plugin() {
    plugin $funcstack[1]
    eval "$funcstack[1] $@"
  }
done; unset _plugin
