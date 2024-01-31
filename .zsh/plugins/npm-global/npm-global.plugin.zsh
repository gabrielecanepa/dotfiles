#!/bin/zsh

##
# Plugin to easily manage global npm packages.
#
function npm() {
  local GLOBAL_COMMANDS=(
    add i in ins inst insta instal isnt isnta isntal isntall
    uninstall unlink remove rm r un
    update up upgrade udpate
  )

  local dir="$(pwd)"
  local args=($@)

  # Initialize params and options.
  local params=()
  local opts=()
  local global=false

  # Parse arguments.
  for arg in $args; do
    if [[ $arg == --global ]]; then
      local global=true
      continue
    fi
    if [[ $arg =~ ^-[\w\d]*g[\w\d]*$ ]]; then
      local global=true
      [[ $arg != -g ]] && opts+=("${arg//-g/}")
      continue
    fi
    if [[ $arg =~ ^--?[\w\d]+$ ]]; then
      opts+=($arg)
      continue
    fi
    params+=($arg)
  done

  unset arg

  # Disable npm fund.
  if [[ "$(command npm config get fund)" == true ]]; then
    command npm config set fund false
  fi

  # Run original command and exit if not global.
  command npm $@
  local npm_exit=$?

  if [[ $npm_exit != 0 || $global != true || ! ${GLOBAL_COMMANDS[@]} =~ $params[1] ]]; then
    echo
    return $npm_exit
  fi

  # Get global node version and npm installation directory.
  cd "$HOME"
  local version="${$(node -v)#v}"
  local version_path=".npm/global/$version"
  [[ ! -d "$version_path" ]] && mkdir -p "$version_path"

  # Switch to directory and dump packages.
  cd "$version_path"
  [[ ! $opts =~ --package-lock-only ]] && opts+=("--package-lock-only")
  command npm $params $opts &>/dev/null

  # Set node engine.
  local engine="$(command npm pkg get engines.node | sed -e 's/[{}"\n]//g')"
  [[ $? != 0 ]] && command npm pkg get engines.node && echo && return $?
  [[ -z "$engine" ]] && command npm pkg set engines.node=$version

  cd "$dir"
  return $npm_exit
}
