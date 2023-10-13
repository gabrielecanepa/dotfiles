#!/bin/zsh

function lts() (
  local LANGS=(node ruby python)
  local args=(${@:2})

  local function validate_language() {
    if [[ -z "$1" ]] || ! [[ " ${LANGS[@]} " =~ " $1 " ]]; then
      echo "${fg[red]}error${reset_color} Invalid option: $1"
      return 1
    fi
  }

  local function get_version_manager() {
    case $1 in
      node) echo "nodenv" ;;
      ruby) echo "rbenv" ;;
      python) echo "pyenv" ;;
      *) return 1 ;;
    esac
  }

  local function get_latest_version() {
    local vm=$(get_version_manager $1)
    local prefix=(${@:2})

    case $1 in
      node|ruby|python)
        local versions="$($vm install --list | sed "s/^[ \t]*//;s/[ \t]*$//")"

        [[ -z "$prefix" ]] &&
        (echo $versions | grep -vi "[A-Za-z\-]" | tail -1) ||
        (echo $versions | grep "^$prefix" | tail -1)
        ;;
      *)
        return 1
        ;;
    esac
  }

  local function get_language_name() {
    case $1 in
      node) echo "Node.js" ;;
      ruby|python) echo "Ruby" ;;
      *) return 1 ;;
    esac
  }

  local function print_help_message() {
    echo "lts is a command line utility to quickly find and install the latest stable version of a language.\n"

    echo "Usage: lts [install] [language] [version]"
    echo "Current language support: ${LANGS[@]}\n"

    echo "Commands:"
    echo "  lts <language> [version]            Get the specified or latest version of a language"
    echo "  lts install                         Install the latest version of all languages"
    echo "  lts install <languages>             Install the latest version of the specified languages"
    echo "  lts install <language> [version]    Install the specified or latest version of a language"
    echo "Examples:"
    echo "  lts node                            Get the latest version of Node.js"
    echo "  lts node 12                         Get latest version 12 of Node.js"
    echo "  lts install node ruby               Install the latest version of Node.js and Ruby"
    echo "  lts install ruby 2.7                Install latest 2.7 version of Ruby"
  }

  case $1 in
    install)
      [[ -z "$args" ]] && local langs=(${LANGS[@]}) || local langs=($args)

      # Check if all languages are supported.
      local unsupported=()

      for lang in $langs; do ! validate_language $lang >/dev/null && unsupported+=($lang); done

      if [[ -n "$unsupported" ]]; then
        echo "${fg[red]}error${reset_color} Unsupported languages: ${unsupported[@]}"
        return 1
      fi

      local updated=()

      for lang in $langs; do
        local vm=$(get_version_manager $lang)
        local current=$($vm global)
        local latest=$(get_latest_version $lang)
        local lang_name=$(get_language_name $lang)

        echo "${fg[blue]}info${reset_color} Installing $lang_name v$latest..."

        $vm install $latest --skip-existing && $vm global $latest

        if [[ $current == $latest ]]; then
          echo "Already on latest version."
          continue
        fi

        echo "${fg[green]} success${reset_color} Updated $lang_name from version $current to $latest."
      done
      ;;
    *)
      if [[ -z $1 ]] || [[ $1 =~ "^(-h|--help)$" ]]; then
        print_help_message
        return 0
      fi

      local lang=$1

      # Check the version manager.
      ! validate_language $lang && return 1

      # Get the version manager.
      local vm=$(get_version_manager $lang)

      # Extract the latest version.
      if [[ -z "$args" ]]; then
        local version="$($vm install --list | grep -vi "[A-Za-z\-]" | tail -1)"
      else
        local version="$($vm install --list | grep "^$args" | tail -1)"
      fi


      [[ -z "$version" ]] && return 1
      
      # Trim and print the latest version.
      echo $version | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//"
  esac
)
