#!/bin/zsh

##
# Plugin to easily manage global npm packages.
#
function npm() {
  local NPM_GLOBAL="$HOME/.npm/global"
  local INSTALL_CMDS=(add i in ins inst insta instal isnt isnta isntal isntall)
  local UNINSTALL_CMDS=(uninstall unlink remove rm r un)
  local UPDATE_CMDS=(update up upgrade udpate)
  local GLOBAL_CMDS=(${INSTALL_CMDS[@]} ${UNINSTALL_CMDS[@]} ${UPDATE_CMDS[@]})

  local npm_fresh() {
    if [[ ! -z "${@:2}" ]]; then
      echo "Unknown arguments: ${@:2}"
      echo
      echo "To update all global dependencies, run:"
      echo "  npm fresh"
      return 1
    fi
    npm update --location=global
    return $?
  }

  local pkg_dependencies() {
    cat ./package.json | jq -r '.dependencies | keys | .[]' | tr '\n' ' '
  }

  local set_pkg_engine() {
    local engine="$(command npm pkg get engines.node | sed -e 's/[{}"\n]//g')"
    [[ $? != 0 ]] && command npm pkg get engines.node && echo && return $?
    [[ -z "$engine" ]] && command npm pkg set engines.node=$version
  }

  if [[ $1 == fresh ]]; then
    npm_fresh $@
    return $?
  fi

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
  done; unset arg

  local cmd="$params[1]"
  local pkgs=($params[2,-1])

  # Run original command and exit if not global.
  if [[ $global != true || ! ${GLOBAL_CMDS[@]} =~ $cmd ]]; then
    command npm $@
    return $?
  fi

  # Get global version and installation directory.
  cd "$HOME"
  local version="${$(node -v)#v}"
  local version_path="$NPM_GLOBAL/$version"
  [[ ! -d "$version_path" ]] && mkdir -p "$version_path"
  cd "$version_path"

  # Check if is an installation cmd
  if [[ $cmd =~ ${INSTALL_CMDS[@]} && ${#pkgs[@]} == 0 ]]; then
    if [[ -f package.json ]]; then
      npm --global install $(pkg_dependencies)
    else
      touch package.json
    fi
  else
    [[ ! $opts =~ --package-lock-only ]] && opts+=("--package-lock-only")
    command npm $params $opts &>/dev/null
  fi

  local exit=$?
  set_pkg_engine
  cd "$dir"
  return $exit












  # Run original command and exit if not global.
  command npm $@
  local npm_exit=$?

  if [[ $npm_exit != 0 || $global != true || ! ${GLOBAL_CMDS[@]} =~ $cmd ]]; then
    return $npm_exit
  fi

  # Get global node version and npm installation directory.
  cd "$HOME"
  local version="${$(node -v)#v}"
  local version_path="$NPM_GLOBAL/$version"
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
