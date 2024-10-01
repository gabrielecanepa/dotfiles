#!/bin/zsh

function _npm() {
  # Global directory
  [[ -z "$NPM_GLOBAL" ]] && export NPM_GLOBAL="$HOME/.npm"
  [[ ! -d "$NPM_GLOBAL" ]] && mkdir -p "$NPM_GLOBAL"

  ##
  # Local functions
  #
  local function _global_dependencies() {
    local dependencies="$(cat "$NPM_GLOBAL/package.json" | jq -r '.dependencies | keys | .[]' | tr '\n' ' ')"
    echo $dependencies
  }

  ##
  # Command to update global npm packages.
  #
  function npm-fresh() {
    if [[ ! -z "${@:2}" ]]; then
      echo "Unknown arguments: ${@:2}"
      echo
      echo "To update all global dependencies, run:"
      echo "  npm fresh"
      return 1
    fi
    command npm update --location=global
  }

  ##
  # Command to dump global npm packages.
  #
  function npm-dump() {
    ! command -v jq >/dev/null && echo "Error: jq is required to dump global npm packages." && return 1

    local dir="$(pwd)"
    local version="$(cd ~ && echo ${$(node -v)#v})"
    local dependencies=($(_global_dependencies))

    case $1 in
      install|uninstall|update)
        local cmd=$1
        local args=(${@:2})
        ;;
      *)
        local args=($@)
        ;;
    esac

    # Check for --node-version
    for arg in $args; do
      if [[ $arg == --node-version=* ]]; then
        version=${arg#--node-version=}
        break
      fi
    done

    if [[ -z "$cmd" && ! -z "${args[@]}" ]]; then
      echo "Unknown arguments: ${args[@]}"
      echo
      echo "To dump all global dependencies, run:"
      echo "  npm dump <cmd> [options]"
      return 1
    fi

    local package_content="{\"dependencies\":{"

    for dependency in $dependencies; do
      package_content+="\"$dependency\": \"*\""
      [[ $dependency != $dependencies[-1] ]] && package_content+=","
    done
    
    package_content+="}}"

    echo $package_content | jq . > $NPM_GLOBAL/package.json

    # Set up the version directory.
    # local version_path="$NPM_GLOBAL/global/$version"
    # [[ ! -d "$version_path" ]] && mkdir -p "$version_path"
    # cd "$version_path"
    # echo "{}" > "$version_path/package.json"

    # command npm pkg set engines.node=$version
    # command npm install $dependencies --package-lock-only >/dev/null
    # exit=$?

    # cd "$dir"
    # return $exit
  }

  ##
  # npm command override to track and manage global packages.
  #
  function npm() {
    local args=($@)
    local cmd=
    local params=()
    local opts=()
    local global=false

    for arg in $args; do
      if [[ $arg == --global ]]; then
        global=true
        continue
      fi
      if [[ $arg =~ ^-[\w\d]*g[\w\d]*$ ]]; then
        global=true
        [[ $arg != -g ]] && opts+=("${arg//-g/}")
        continue
      fi
      if [[ $arg =~ ^--?[\w\d]+$ ]]; then
        opts+=($arg)
        continue
      fi
      params+=($arg)
    done

    local cmd=${params[1]}
    local pkgs=${params[@]:1}

    if [[ $global != true && ! $cmd =~ ^(dump|fresh)$ ]]; then
      command npm $@
      return $?
    fi

    case $cmd in
      dump|fresh)
        eval "npm-$cmd $@"
        ;;
      install|add|i|in|ins|inst|insta|instal|isnt|isnta|isntal|isntall|uninstall|unlink|remove|rm|r|un|update|up|upgrade|udpate)
        if [[ ${#pkgs} == 0 ]]; then
          command npm -g $cmd $(_global_dependencies)
        else
          command npm $@
        fi
        exit=$?
        npm-dump >/dev/null
        return $exit
        ;;
      *)
        command npm $@
        ;;
    esac
  }
}

function _nodenv() {
  ##
  # Function override to align global npm packages among different node versions.
  #
  function nodenv() {
    local CMDS=(global install)
    local cmd=$1
    local version=$2
    local versions=(${@:2})
    local current=$(command nodenv global)

    command nodenv $@
    exit=$?
    [[ $exit != 0 ]] && return $exit
    [[ $(command nodenv global) == $current || ! $cmd =~ ${^CMDS} ]] && return 0

    npm -g install >/dev/null
  }
}

command -v npm >/dev/null && _npm
command -v nodenv >/dev/null && _nodenv
unset -f _npm _nodenv
