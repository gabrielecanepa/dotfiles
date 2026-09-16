_node_bin_update() {
  emulate -L zsh

  if [[ -n "$_NODE_BIN_CURRENT" ]]; then
    path=("${(@)path:#$_NODE_BIN_CURRENT}")
    unset _NODE_BIN_CURRENT
  fi

  local dir="$PWD"
  while [[ -n "$dir" ]]; do
    if [[ -d "$dir/node_modules/.bin" ]]; then
      path+=("$dir/node_modules/.bin")
      typeset -g _NODE_BIN_CURRENT="$dir/node_modules/.bin"
      return 0
    fi
    [[ "$dir" == / ]] && break
    dir="${dir:h}"
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _node_bin_update
_node_bin_update
