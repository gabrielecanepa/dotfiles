# Put the current project's node_modules/.bin on PATH so local binaries run as bare commands inside the project.

_local_bin_update() {
  emulate -L zsh

  # Remove the marked entry from a prior run so PATH does not accumulate.
  if [[ -n "$_LOCAL_BIN_CURRENT" ]]; then
    path=("${(@)path:#$_LOCAL_BIN_CURRENT}")
    unset _LOCAL_BIN_CURRENT
  fi

  local dir="$PWD"
  while [[ -n "$dir" ]]; do
    if [[ -d "$dir/node_modules/.bin" ]]; then
      # Append, never prepend: a project's local binary must not shadow a real system command.
      path+=("$dir/node_modules/.bin")
      typeset -g _LOCAL_BIN_CURRENT="$dir/node_modules/.bin"
      return 0
    fi
    [[ "$dir" == / ]] && break
    dir="${dir:h}"
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _local_bin_update
_local_bin_update
