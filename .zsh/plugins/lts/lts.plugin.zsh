#!/bin/zsh

function lts() (
  local LANGS=(node ruby python)
  local args=(${@:2})

  local function check_lang() {
    if [[ -z "$1" ]] || ! [[ " ${LANGS[@]} " =~ " $1 " ]]; then
      echo "${fg[red]}error${reset_color} You must specify a supported language."
      return 1
    fi
  }

  case "$1" in
    upgrade)
      [[ -z "$args" ]] && local args=(${LANGS[@]})

      # Check if all languages are supported.
      local unsupported=()

      for arg in $args; do  ! check_lang $arg >/dev/null && unsupported+=($arg); done

      if [[ -n "$unsupported" ]]; then
        echo "${fg[red]}error${reset_color} Unsupported languages: ${unsupported[@]}"
        return 1
      fi

      for lang in $args; do
        echo "${fg[blue]}info${reset_color} Installing latest ${(C)lang} version..."

        case $lang in
          node)
            fnm install --lts && fnm use lts-latest
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

      local function get_versions() {
        case $1 in
          python)
            local versions="$(pyenv install -l)"
            ;;
          ruby)
            local versions="$(rbenv install -L)"
            ;;
          *)
            return 1
            ;;
        esac

        echo $versions | sed 's/^[ \t]*//;s/[ \t]*$//'
      }

      # Check the version manager.
      ! check_lang $lang && return 1

      # Extract the latest version.
      if [[ -z "$args" ]]; then
        local version="$(get_versions $lang | grep -vi "[A-Za-z\-]" | tail -1)"
      else
        local version="$(get_versions $lang | grep "^$args" | tail -1)"
      fi

      [[ -z "$version" ]] && return 1 || echo $version
  esac
)
