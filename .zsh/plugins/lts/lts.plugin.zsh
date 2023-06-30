#!/bin/zsh

function lts() (
  local LANGS=(node ruby python)
  local args=(${@:2})

  local function validate_language() {
    if [[ -z "$1" ]] || ! [[ " ${LANGS[@]} " =~ " $1 " ]]; then
      echo "${fg[red]}error${reset_color} You must specify a supported language."
      return 1
    fi
  }

  local function get_version_manager() {
    case $1 in
      node)
        echo "nodenv"
        ;;
      ruby)
        echo "rbenv"
        ;;
      python)
        echo "pyenv"
        ;;
      *)
        return 1
        ;;
    esac
  }

  local function get_latest_version() {
    local args=(${@:2})
    local vm=$(get_version_manager $1)

    case $1 in
      node|ruby|python)
        local versions="$($vm install --list | sed "s/^[ \t]*//;s/[ \t]*$//")"

        [[ -z "$2" ]] && \
        echo $versions | grep -vi "[A-Za-z\-]" | tail -1 || \
        echo $versions | grep "^$args" | tail -1
        ;;
      *)
        return 1
        ;;
    esac
  }

  case "$1" in
    install|upgrade)
      [[ -z "$args" ]] && local langs=(${LANGS[@]}) || local langs=($args)

      # Check if all languages are supported.
      local unsupported=()

      for lang in $langs; do ! validate_language $lang >/dev/null && unsupported+=($lang); done

      if [[ -n "$unsupported" ]]; then
        echo "${fg[red]}error${reset_color} Unsupported languages: ${unsupported[@]}"
        return 1
      fi

      for lang in $langs; do
        local prefix="$(echo $2 | cut -d. -f1,2)"

        echo "${fg[blue]}info${reset_color} Installing latest ${(C)lang} version..."

        local current="$(lts $lang)"

        case $lang in
          node)
            nodenv install $(lts node) --skip-existing && nodenv global $(lts node)
            if [[ "$current" == "$(lts node)" ]]; then
              echo "Already on latest version."
            fi
            ;;
          ruby)
            local current="$(lts ruby)"
            rbenv install $(lts ruby) --skip-existing && rbenv global $(lts ruby)
            if [[ "$current" == "$(lts ruby)" ]]; then
              echo "Already on latest version."
            fi
            ;;
          python)
            local current="$(lts python)"
            pyenv install $(lts python) --skip-existing && pyenv global $(lts python)
            if [[ "$current" == "$(lts python)" ]]; then
              echo "Already on latest version."
            fi
            ;;
        esac

        echo ""
      done

      echo "${fg[green]}success${reset_color} Done! All languages are up-to-date."
      ;;
    *)
      local lang=$1
      local vm=$(get_version_manager $lang)

      # Check the version manager.
      ! validate_language $lang && return 1

      # Extract the latest version.
      if [[ -z "$args" ]]; then
        local version="$($vm install --list | grep -vi "[A-Za-z\-]" | tail -1)"
      else
        local version="$($vm install --list | grep "^$args" | tail -1)"
      fi

      [[ -z "$version" ]] && return 1 || echo $version
  esac
)
