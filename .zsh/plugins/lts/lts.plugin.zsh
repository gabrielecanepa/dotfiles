#!/bin/zsh

function lts() (
  local LANGS=(node python ruby)

  local function print_help_message() {
    echo "Command line utility to quickly find and install the latest stable version of common programming languages.\n"

    echo "Usage: lts [install|i] <language@prefix>"
    echo "Supported languages: ${LANGS[@]}\n"

    echo "Commands:"
    echo "  lts <language@prefix>               Get the latest version of a language matching an optional prefix"
    echo "  lts install                         Install the latest version of all languages"
    echo "  lts i <language@prefix>       Install the latest version of the specified languages matching an optional prefix"
    echo "Examples:"
    echo "  lts node                            Get the latest version of Node"
    echo "  lts node@18                         Get the latest minor version of Node 18"
    echo "  lts install python ruby@2           Install the latest version of Python and Ruby 2"
    echo "  lts install ruby@2.6                Install the latest patch of Ruby 2.6"
  }

  local function validate_language() {
    if [[ -z "$1" ]] || ! [[ " ${LANGS[@]} " =~ " $1 " ]]; then
      return 1
    fi
  }

  local function get_version_manager() {
    case $1 in
      node) echo "nodenv" ;;
      python) echo "pyenv" ;;
      ruby) echo "rbenv" ;;
      *) return 1 ;;
    esac
  }

  local function get_latest_version() {
    local parts=(${(s/@/)1})

    if [[ ${#parts[@]} > 2 ]] || [[ $1 =~ "@" && -z $parts[2] ]]; then
      echo "${fg[red]}ERROR${reset_color} Invalid version: $1"
      return 1
    fi

    local lang=${parts[1]}
    local prefix=${parts[2]}
    local vm=$(get_version_manager $lang)

    case $lang in
      node|python)
        local opt="--list"
        ;;
      ruby)
        local opt="--list-all"
        ;;
      *)
        return 1
        ;;
    esac

    local versions="$($vm install $opt | grep -vi "[A-Za-z\-]" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//")"

    if [[ ! -z "$prefix" ]]; then
      if [[ $prefix =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        versions="$(echo $versions | grep "^$prefix")"
      else
        versions="$(echo $versions | grep "^$prefix\\.")"
      fi
    fi

    echo $versions | tail -1
  }

  local function get_language_name() {
    case $1 in
      node) echo "Node.js" ;;
      python) echo "Python" ;;
      ruby) echo "Ruby" ;;
      *) return 1 ;;
    esac
  }

  case $1 in
    install|i)
      local args=(${@:2})
      [[ -z "$args" ]] && local versions=(${LANGS[@]}) || local versions=($args)

      local updated=()

      for version in $versions; do
        local parts=(${(s/@/)version})
        local lang=${parts[1]}
        local prefix=${parts[2]}

        if ! validate_language $lang; then
          echo "${fg[red]}ERROR${reset_color} Invalid argument: $version"
          return 1
        fi

        local lang_name=$(get_language_name $lang)
        local vm=$(get_version_manager $lang)

        local old=$($vm global)
        local new=$(get_latest_version $version)

        if [[ $old == $new ]]; then
          if [[ "$(lts $lang)" == $new ]]; then
            echo "Already on latest $lang_name version"
            continue
          fi

          local prefix_parts=(${(s/./)prefix})

          if [[ ${#prefix_parts[@]} > 2 ]]; then
            echo "$lang_name $new is already installed"
            continue
          fi

          echo "Already on latest $lang_name $prefix version ($new)"
          continue
        fi

        if $vm versions | grep -q $new; then
          echo -n "$lang_name $new is already installed. Do you want to switch to it? [Y/n] "
          read -k1 -r choice
          [[ ! $choice =~ ^[Nn]$ ]] && $vm global $new
          unset choice
          continue
        fi

        if ! $vm install $new --skip-existing; then
          echo "${fg[red]}ERROR${reset_color} Failed to install $lang_name $new"
          return 1
        fi
        if ! $vm global $new; then
          echo "${fg[red]}ERROR${reset_color} Failed to set $lang_name version to $new"
          return 1
        fi
      done
      ;;
    *)
      local args=($@)

      if [[ -z $args ]] || [[ $args =~ "^(-h|--help)$" ]]; then
        print_help_message
        return 0
      fi

      if [[ ${#args[@]} > 1 ]]; then
        echo "${fg[red]}ERROR${reset_color} Invalid arguments: ${args[@]}"
        return 1
      fi

      local parts=(${(s/@/)args})
      local lang=${parts[1]}

      if ! validate_language $lang; then
        echo "${fg[red]}ERROR${reset_color} Invalid argument: $lang"
        return 1
      fi

      local version=$(get_latest_version $1)
      [[ -z "$version" ]] && return 1
      echo $version
  esac
)
