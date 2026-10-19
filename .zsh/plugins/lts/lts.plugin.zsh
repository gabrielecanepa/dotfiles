typeset -ga _lts_langs=(node ruby python)

_lts_print_help() {
  emulate -L zsh
  print -r -- 'Usage: lts <command>'
  print -r --
  print -r -- 'Commands:'
  print -r -- '  <language>[@<prefix>]                Print the latest LTS release matching an optional version prefix.'
  print -r -- '  check [<language>]                   Compare the active version against the latest LTS, for one or all languages.'
  print -r -- '  install [<language>[@<prefix>]...]   Install the latest LTS of all supported languages or the specified languages.'
  print -r -- '  i [<language>[@<prefix>]...]         Install the latest LTS of all supported languages or the specified languages.'
  print -r --
  print -r -- "Languages: ${_lts_langs[*]}"
  print -r --
  print -r -- 'Examples:'
  print -r -- '  lts node                    Get the latest Node.js LTS release.'
  print -r -- '  lts node@18                 Get the latest minor LTS version of Node.js 18.'
  print -r -- '  lts check                   Compare every active version against its latest LTS.'
  print -r -- '  lts check node              Compare the active Node.js version against the latest LTS.'
  print -r -- '  lts install python ruby@2   Install the latest LTS of Python and Ruby 2.'
  print -r -- '  lts install ruby@2.6        Install the latest LTS patch of Ruby 2.6.'
}

_lts_error() {
  emulate -L zsh
  print -ru2 -- "lts: $*"
}

_lts_validate_language() {
  emulate -L zsh
  local lang=$1
  [[ -n $lang ]] && (( ${_lts_langs[(Ie)$lang]} ))
}

_lts_parse_spec() {
  emulate -L zsh
  local MATCH MBEGIN MEND match mbegin mend
  local spec=$1 lang=${1%%@*} prefix=''
  if [[ $spec == *@* ]]; then
    prefix=${spec#*@}
    [[ $prefix =~ '^[0-9]+(\.[0-9]+){0,2}$' ]] || return 1
  fi
  reply=("$lang" "$prefix")
}

_lts_get_version_manager() {
  emulate -L zsh
  case $1 in
    node) print -r -- nodenv ;;
    python) print -r -- pyenv ;;
    ruby) print -r -- rbenv ;;
    *) return 1 ;;
  esac
}

_lts_get_language_name() {
  emulate -L zsh
  case $1 in
    node) print -r -- 'Node.js' ;;
    python) print -r -- 'Python' ;;
    ruby) print -r -- 'Ruby' ;;
    *) return 1 ;;
  esac
}

_lts_get_latest_version() {
  emulate -L zsh
  setopt local_options pipefail extended_glob

  local spec=$1
  local -a reply
  if ! _lts_parse_spec "$spec"; then
    _lts_error "invalid version: $spec"
    return 1
  fi

  local lang=${reply[1]}
  local prefix=${reply[2]}
  local vm
  vm=$(_lts_get_version_manager "$lang") || return 1

  if [[ $lang == node ]]; then
    local releases version date files npm v8 uv zlib openssl modules lts security
    releases=$(command curl -fsSL --max-time 10 https://nodejs.org/dist/index.tab) || return 1

    while IFS=$'\t' read -r version date files npm v8 uv zlib openssl modules lts security; do
      [[ $version == v[0-9]##.[0-9]##.[0-9]## && $lts != - ]] || continue
      version=${version#v}
      if [[ -n $prefix ]]; then
        if [[ $prefix == [0-9]##.[0-9]##.[0-9]## ]]; then
          [[ $version == $prefix ]] || continue
        else
          [[ $version == $prefix.* ]] || continue
        fi
      fi
      print -r -- $version
      return 0
    done <<< $releases
    _lts_error "no release found: $spec"
    return 1
  fi

  if (( ! ${+commands[$vm]} )); then
    _lts_error "required tool not found: $vm"
    return 1
  fi

  local opt
  case $lang in
    python) opt='--list' ;;
    ruby) opt='--list-all' ;;
    *) return 1 ;;
  esac

  local versions
  versions=$(command $vm install $opt |
    command grep -vi '[A-Za-z\-]' |
    command sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') || return 1

  if [[ -n $prefix ]]; then
    local re=${prefix//./\\.}
    if [[ $prefix == [0-9]##.[0-9]##.[0-9]## ]]; then
      versions=$(print -r -- "$versions" | command grep "^$re$")
    else
      versions=$(print -r -- "$versions" | command grep "^$re\\.")
    fi
  fi

  if [[ -z $versions ]]; then
    _lts_error "no release found: $spec"
    return 1
  fi
  print -r -- $versions | command tail -1
}

_lts_get_active_version() {
  emulate -L zsh
  local vm
  vm=$(_lts_get_version_manager "$1") || return 1

  if (( ! ${+commands[$vm]} )); then
    _lts_error "required tool not found: $vm"
    return 1
  fi

  command $vm version-name
}

_lts_colorize() {
  emulate -L zsh
  local color=$1 text=$2
  if (( _lts_use_color )); then
    print -nP -- "%F{$color}${text}%f"
  else
    print -rn -- "$text"
  fi
}

_lts_check_language() {
  emulate -L zsh
  local lang=$1 labelled=$2 lang_name active latest

  lang_name=$(_lts_get_language_name $lang) || return 2
  active=$(_lts_get_active_version $lang) || return 2
  latest=$(_lts_get_latest_version $lang) || return 2
  [[ -z $active || -z $latest ]] && return 2
  _lts_check_latest=$latest

  if [[ $active == $latest ]]; then
    if [[ -n $labelled ]]; then
      print -r -- "${lang_name}: $(_lts_colorize green "$active") (latest)"
    else
      print -r -- "Already on latest version ($(_lts_colorize green "$active"))"
    fi
    return 0
  fi

  local prefix=''
  [[ -n $labelled ]] && prefix="${lang_name}: "
  print -r -- "${prefix}$(_lts_colorize yellow "$active") → $(_lts_colorize green "$latest")"
  return 1
}

_lts_check() {
  emulate -L zsh

  if (( $# > 1 )); then
    _lts_error "invalid arguments: $*"
    return 1
  fi

  local _lts_use_color=0
  [[ -t 1 && -z ${NO_COLOR-} && ${TERM-} != dumb ]] && _lts_use_color=1
  local _lts_check_latest

  if (( $# == 1 )); then
    local lang=$1
    if ! _lts_validate_language "$lang"; then
      _lts_error "invalid argument: $lang"
      return 1
    fi

    _lts_check_language $lang
    case $? in
      0) ;;
      1) print -r -- "Run \`lts install $lang\` to upgrade to $_lts_check_latest" ;;
      *) return 1 ;;
    esac
    return 0
  fi

  local lang any_outdated=0
  for lang in "${_lts_langs[@]}"; do
    _lts_check_language $lang labelled
    case $? in
      0) ;;
      1) any_outdated=1 ;;
      *) return 1 ;;
    esac
  done

  if (( any_outdated )); then
    print -r -- 'Run `lts install` to upgrade to the latest versions'
  else
    print -r -- 'Already on the latest versions'
  fi
}

_lts_install() {
  emulate -L zsh

  local -a versions
  if (( $# )); then
    versions=("$@")
  else
    versions=("${_lts_langs[@]}")
  fi

  local spec lang prefix lang_name vm old new choice
  local -a reply prefix_parts

  for spec in "${versions[@]}"; do
    if ! _lts_parse_spec "$spec"; then
      _lts_error "invalid argument: $spec"
      return 1
    fi
    lang=${reply[1]}
    prefix=${reply[2]}

    if ! _lts_validate_language "$lang"; then
      _lts_error "invalid argument: $spec"
      return 1
    fi

    lang_name=$(_lts_get_language_name $lang)
    vm=$(_lts_get_version_manager $lang)

    if (( ! ${+commands[$vm]} )); then
      _lts_error "required tool not found: $vm"
      return 1
    fi
    old=$(command $vm global) || return 1
    new=$(_lts_get_latest_version $spec) || return 1
    if [[ -z $new ]]; then
      _lts_error "no release found: $spec"
      return 1
    fi

    if [[ $old == $new ]]; then
      # The prefixed latest is already active, check if it's also the global latest.
      if [[ $(_lts_get_latest_version $lang) == $new ]]; then
        print -r -- "Already on latest $lang_name version"
        continue
      fi

      prefix_parts=(${(s/./)prefix})
      if (( ${#prefix_parts} > 2 )); then
        print -r -- "$lang_name $new is already installed"
        continue
      fi

      print -r -- "Already on latest $lang_name $prefix version ($new)"
      continue
    fi

    if command $vm versions --bare | command grep -Fxq -- $new; then
      print -rn -- "$lang_name $new is already installed. Do you want to switch to it? [Y/n] "
      read -k1 -r choice || return 1
      if [[ $choice != [Nn] ]]; then
        command $vm global $new || {
          _lts_error "failed to set $lang_name version to $new"
          return 1
        }
      fi
      continue
    fi

    if ! command $vm install $new --skip-existing; then
      _lts_error "failed to install $lang_name $new"
      return 1
    fi
    if ! command $vm global $new; then
      _lts_error "failed to set $lang_name version to $new"
      return 1
    fi
  done
}

_lts_query() {
  emulate -L zsh

  if (( $# == 0 )) || [[ $1 == (-h|--help) ]]; then
    _lts_print_help
    return 0
  fi

  if (( $# > 1 )); then
    _lts_error "invalid arguments: $*"
    return 1
  fi

  local -a reply
  if ! _lts_parse_spec "$1"; then
    _lts_error "invalid argument: $1"
    return 1
  fi
  local lang=${reply[1]}

  if ! _lts_validate_language "$lang"; then
    _lts_error "invalid argument: $lang"
    return 1
  fi

  local version
  version=$(_lts_get_latest_version "$1") || return 1
  [[ -z $version ]] && return 1
  print -r -- $version
}

lts() {
  emulate -L zsh

  case $1 in
    install|i)
      _lts_install "${@:2}"
      ;;
    check)
      _lts_check "${@:2}"
      ;;
    *)
      _lts_query "$@"
      ;;
  esac
}
