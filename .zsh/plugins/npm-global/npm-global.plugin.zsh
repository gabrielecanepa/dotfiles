#!/bin/zsh

function npm-global() {
  # Default global directory
  [[ -z "$NPM_GLOBAL" ]] && export NPM_GLOBAL="$HOME/.npm"
  [[ ! -d "$NPM_GLOBAL" ]] && mkdir -p "$NPM_GLOBAL"

  ##
  # Prints the current node version.
  #
  local function node_version() {
    cd ~
    echo ${$(node -v)#v}
  }

  ##
  # Prints a list of the globally install dependencies.
  #
  local function global_dependencies() {
    command npm list -g --depth=0 | sed -e '1d' -e 's/^[^ ]* //' | tr '\n' ' ' | sed 's/[[:space:]]*$//'
  }

  ##
  # Prints a list of the locally install dependencies.
  #
  local function local_dependencies() {
    jq -r '.dependencies | keys[]' package.json 2>/dev/null
  }

  ##
  # Dumps global dependencies to the version-specific package.json located in NPM_GLOBAL.
  #
  function npm-dump() {
    local dir=$NPM_GLOBAL/$(node_version)
    mkdir -p $dir
    cd $dir

    if [[ -f package.json ]]; then
      command npm uninstall $(jq -r '.dependencies | keys[]' package.json | tr '\n' ' ')
    fi

    echo "{\n  \"engines\": {\n    \"node\": \"$(node_version)\"\n  }\n}" > package.json
    command npm install $(global_dependencies)
    local exit=$?
    rm -rf node_modules
    cd - >/dev/null
    return $exit
  }

  ##
  # Background process to dump global dependencies.
  #
  local function npm-background-dump() {
    ((npm-dump) &>/dev/null &) &>/dev/null
  }

  ##
  # Updates and syncs global npm packages.
  #
  function npm-fresh() {
    if [[ ! -z "${@:2}" ]]; then
      echo "Unknown arguments: ${@:2}"
      echo
      echo "To update all global dependencies, run:"
      echo "  npm fresh"
      return 1
    fi
    command npm -g update
    local exit=$?
    npm-background-dump
    return $exit
  }

  ##
  # npm command override to track and manage global packages.
  #
  function npm() {
    local args=($@)
    local global=false

    for arg in $args; do
      if [[ $arg == --global || $arg =~ ^-[\w\d]*g[\w\d]*$ ]]; then
        global=true
        break
      fi
    done

    if [[ $global == false ]]; then
      case $1 in
        dump)
          npm-dump
          ;;
        fresh)
          npm-fresh
          ;;
        *)
          command npm $@
          ;;
      esac
      return $?
    fi

    command npm $@
    local exit=$?

    local DUMP_COMMANDS=(
      install add i in ins inst insta instal isnt isntal isntall
      uninstall unlink remove rm r
      un update up upgrade udpate
    )
    for cmd in $DUMP_COMMANDS; do
      if [[ $@ == *$cmd* ]]; then
        npm-background-dump
        break
      fi
    done
    
    return $exit
  }

  function nodenv () {
    command nodenv $@
    local exit=$?

    case $1 in
      install)
        ((npm install $(global_dependencies) --global && npm-dump) &>/dev/null &) &>/dev/null
        ;;
    esac

    return $exit
  }
}

npm-global
unset -f npm-global
