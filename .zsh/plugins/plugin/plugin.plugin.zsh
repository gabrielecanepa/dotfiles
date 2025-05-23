#!/bin/zsh

# Dinamically load a Zsh plugin.
# Usage: plugin <name>
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

for _plugin in $lazy_plugins; do
  plugin_name="$_plugin"
  zsh_path="$ZSH/plugins/$plugin_name/$plugin_name.plugin.zsh"
  custom_path="$ZSH_CUSTOM/plugins/$plugin_name/$plugin_name.plugin.zsh"
  [[ -f "$custom_path" ]] && zsh_path="$custom_path"

  if [[ ! -f "$zsh_path" && ! -f "$custom_path" ]]; then
    echo "Plugin not found: $plugin_name"
    continue
  fi

  function $_plugin() {
    # Load the plugin
    . "$zsh_path"

    # Store the loaded plugin function in a new function
    function _plugin_func() {
      eval "$_plugin $@"
    }

    # Redefine the plugin function
    function $funcstack[1]() {
      # eval "$funcstack[2] $@"
      _plugin_func $@
    }

    # Call the new plugin function
    $funcstack[1] $@
  }
done
