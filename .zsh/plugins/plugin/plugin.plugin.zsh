# Load or reload a zsh plugin by name, preferring the custom override over the bundled copy.
#
# Usage: plugin <name>

plugin() {
  emulate -L zsh

  local name="$1"

  if [[ -z "$name" || "$name" == "-h" || "$name" == "--help" ]]; then
    print -r -- 'Usage: plugin <name>'
    return 0
  fi

  local zsh_path="$ZSH/plugins/$name/$name.plugin.zsh"
  local custom_path="$ZSH_CUSTOM/plugins/$name/$name.plugin.zsh"
  # A plugin under ZSH_CUSTOM shadows the bundled one of the same name.
  [[ -f "$custom_path" ]] && zsh_path="$custom_path"

  if [[ ! -f "$zsh_path" ]]; then
    print -r -- "Plugin not found: $name"
    return 1
  fi

  source "$zsh_path"
}
