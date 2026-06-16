#!/bin/zsh

function npm-global() {
  [[ -z "$NPM_GLOBAL" ]] && export NPM_GLOBAL="$HOME/.npm"
  mkdir -p "$NPM_GLOBAL"

  INSTALL_COMMANDS=(
    install add i in ins inst insta instal isnt isntal isntall
  )
  DUMP_COMMANDS=(
    $INSTALL_COMMANDS
    uninstall unlink remove rm r
    un update up upgrade udpate
  )

  local function global_deps() {
    # Strip the ' -> path' suffix so symlinked (linked) globals stay valid specs.
    command npm list -g --depth=0 | sed -e '1d' -e 's/^[^ ]* //' -e 's/ ->.*$//' | tr '\n' ' ' | sed 's/[[:space:]]*$//'
  }

  local function saved_deps() {
    [[ -f "$NPM_GLOBAL/package.json" ]] || return 0
    command node -p 'const d=require(process.argv[1]).dependencies||{};Object.entries(d).map(([k,v])=>`${k}@${v}`).join("\n")' "$NPM_GLOBAL/package.json" 2>/dev/null
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
    (
      cd "$NPM_GLOBAL" || exit 1
      echo "{}" > package.json
      command npm install $(global_deps) --package-lock-only
      install_exit=$?
      rm -rf node_modules
      exit $install_exit
    )
    return $?
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
    local -a positional

    for arg in $args; do
      if [[ $arg == --global || $arg =~ ^-[\w\d]*g[\w\d]*$ ]]; then
        global=true
      elif [[ $arg != -* ]]; then
        positional+=$arg
        [[ -z $cmd ]] && cmd=$arg
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

    # A bare global install (no package arguments) restores the tracked
    # dependencies from $NPM_GLOBAL/package.json instead of falling through to
    # npm, which would operate on the current directory and then dump.
    if (( ${#positional} <= 1 )) && (( ${INSTALL_COMMANDS[(Ie)$cmd]} )); then
      local -a deps
      deps=(${(f)"$(saved_deps)"})
      if (( ${#deps} == 0 )); then
        echo "No global dependencies tracked in $NPM_GLOBAL/package.json" >&2
        return 1
      fi
      command npm install --global $deps
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
