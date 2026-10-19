_node_modules_bin_update() {
  emulate -L zsh

  if [[ -n ${_NODE_BIN_CURRENT:-} ]]; then
    local index=${path[(Ie)$_NODE_BIN_CURRENT]}
    (( index )) && path[$index]=()
    unset _NODE_BIN_CURRENT
  fi

  local dir=$PWD bin
  while [[ -n $dir ]]; do
    if [[ -d $dir/node_modules/.bin ]]; then
      bin=$dir/node_modules/.bin
      if (( ! ${path[(Ie)$bin]} )); then
        path+=($bin)
        typeset -g _NODE_BIN_CURRENT=$bin
      fi
      return 0
    fi
    [[ $dir == / ]] && break
    dir=${dir:h}
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _node_modules_bin_update
_node_modules_bin_update
