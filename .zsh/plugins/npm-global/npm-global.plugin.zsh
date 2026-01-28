#!/bin/zsh

function npm-global() {
  # Default global directory
  [[ -z "$NPM_GLOBAL" ]] && export NPM_GLOBAL="$HOME/.npm"
  mkdir -p "$NPM_GLOBAL"

  # Define commands that trigger a dump
  DUMP_COMMANDS=(
    install add i in ins inst insta instal isnt isntal isntall
    uninstall unlink remove rm r
    un update up upgrade udpate
  )

  ##
  # Prints a list of the globally install dependencies.
  #
  local function global_deps() {
    command npm list -g --depth=0 | sed -e '1d' -e 's/^[^ ]* //' | tr '\n' ' ' | sed 's/[[:space:]]*$//'
  }

  ##
  # Dumps global dependencies to the version-specific package.json located in $NPM_GLOBAL.
  #
  function npm-dump() {
    if [[ ! -z $1 ]]; then
      echo "Unknown arguments: $@"
      echo
      echo "To dump global dependencies, run:"
      echo "  npm dump"
      return 1
    fi
    cd $NPM_GLOBAL
    echo "{}" > package.json
    command npm install $(global_deps) --package-lock-only
    local exit=$?
    rm -rf node_modules
    cd - >/dev/null
    return $exit
  }

  ##
  # Updates and syncs global npm packages.
  #
  function npm-fresh() {
    if [[ ! -z $1 ]]; then
      echo "Unknown arguments: $@"
      echo
      echo "To update all global dependencies, run:"
      echo "  npm fresh"
      return 1
    fi
    command npm -g update
    local exit=$?
    ((npm-dump) &>/dev/null &) &>/dev/null
    return $exit
  }

  ##
  # npm command override to track and manage global packages.
  #
  function npm() {
    local args=($@)
    local cmd
    local global=false

    for arg in $args; do
      if [[ $arg == --global || $arg =~ ^-[\w\d]*g[\w\d]*$ ]]; then
        global=true
      else
        if [[ -z $cmd ]] && [[ $arg != -* ]]; then
          cmd=$arg
        fi
      fi
    done

    if [[ $global == false ]]; then
      case $1 in
        dump|fresh)
          npm-$1 ${@:2}
          ;;
        *)
          command npm $@
          ;;
      esac
      return $?
    fi

    command npm $@
    local exit=$?

    for dump_cmd in $DUMP_COMMANDS; do
      if [[ $dump_cmd == $cmd ]]; then
        ((npm-dump) &>/dev/null &) &>/dev/null
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
        ((npm install $(global_deps) --global && npm-dump) &>/dev/null &) &>/dev/null
        ;;
    esac

    return $exit
  }
}

npm-global
unset -f npm-global
