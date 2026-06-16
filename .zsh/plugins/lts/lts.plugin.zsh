# Find and install the latest LTS release of Node.js, Python, or Ruby via their version managers.
#
# Usage: lts <command>

typeset -ga _lts_langs=(node python ruby)

_lts_print_help() {
  emulate -L zsh
  print -r -- 'Usage: lts <command>'
  print -r --
  print -r -- 'Commands:'
  print -r -- '    <language@prefix>      Print the latest LTS release matching an optional version prefix.'
  print -r -- '    install               Install the latest LTS of all supported languages.'
  print -r -- '    i <language@prefix>   Install the latest LTS of the specified languages.'
  print -r --
  print -r -- "Languages: ${_lts_langs[*]}"
  print -r --
  print -r -- 'Examples:'
  print -r -- '    lts node                    Get the latest Node.js LTS release.'
  print -r -- '    lts node@18                 Get the latest minor LTS version of Node.js 18.'
  print -r -- '    lts install python ruby@2   Install the latest LTS of Python and Ruby 2.'
  print -r -- '    lts install ruby@2.6        Install the latest LTS patch of Ruby 2.6.'
}

_lts_error() {
  emulate -L zsh
  print -P -- "%F{red}ERROR%f $*" >&2
}

_lts_validate_language() {
  emulate -L zsh
  local lang=$1
  # (Ie) returns the index of $lang in the array, 0 (false) when absent.
  [[ -n $lang ]] && (( ${_lts_langs[(Ie)$lang]} ))
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

# Resolve the latest LTS version for a language@prefix spec.
_lts_get_latest_version() {
  emulate -L zsh
  setopt local_options pipefail extended_glob

  local spec=$1
  # Split the spec on @ into language and optional version prefix.
  local -a parts=(${(s/@/)spec})

  # Reject more than one @ or a trailing @ with no prefix.
  if (( ${#parts} > 2 )) || [[ $spec == *@* && -z ${parts[2]} ]]; then
    _lts_error "Invalid version: $spec"
    return 1
  fi

  local lang=${parts[1]}
  local prefix=${parts[2]}
  local vm
  vm=$(_lts_get_version_manager "$lang") || return 1

  if (( ! ${+commands[$vm]} )); then
    _lts_error "Required tool not found: $vm"
    return 1
  fi

  # Node LTS comes from the dist index rather than a version-manager list.
  if [[ $lang == node ]]; then
    if (( ! ${+commands[jq]} )); then
      _lts_error 'Required tool not found: jq'
      return 1
    fi
    command curl -s https://nodejs.org/dist/index.json |
      command jq -r 'map(select(.lts != false)) | .[0].version' |
      command sed 's/^v//'
    return $?
  fi

  local opt
  case $lang in
    python) opt='--list' ;;
    ruby) opt='--list-all' ;;
    *) return 1 ;;
  esac

  local versions
  # Drop any line carrying letters (named/dev builds) and trim surrounding whitespace.
  versions=$(command "$vm" install "$opt" |
    command grep -vi '[A-Za-z\-]' |
    command sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') || return 1

  if [[ -n $prefix ]]; then
    # A full x.y.z prefix matches exactly; a partial prefix matches up to its next dot.
    if [[ $prefix == [0-9]##.[0-9]##.[0-9]## ]]; then
      versions=$(print -r -- "$versions" | command grep "^$prefix")
    else
      versions=$(print -r -- "$versions" | command grep "^$prefix\\.")
    fi
  fi

  # Versions are sorted ascending, so the last line is the newest match.
  print -r -- "$versions" | command tail -1
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
  local -a parts prefix_parts

  for spec in "${versions[@]}"; do
    parts=(${(s/@/)spec})
    lang=${parts[1]}
    prefix=${parts[2]}

    if ! _lts_validate_language "$lang"; then
      _lts_error "Invalid argument: $spec"
      return 1
    fi

    lang_name=$(_lts_get_language_name "$lang")
    vm=$(_lts_get_version_manager "$lang")

    old=$(command "$vm" global)
    new=$(_lts_get_latest_version "$spec") || return 1

    if [[ $old == "$new" ]]; then
      # The active version already matches the prefixed latest; check whether it is also the global latest.
      if [[ $(_lts_get_latest_version "$lang") == "$new" ]]; then
        print -r -- "Already on latest $lang_name version"
        continue
      fi

      prefix_parts=(${(s/./)prefix})

      # A full x.y.z prefix pins one release, so there is nothing newer to move to.
      if (( ${#prefix_parts} > 2 )); then
        print -r -- "$lang_name $new is already installed"
        continue
      fi

      print -r -- "Already on latest $lang_name $prefix version ($new)"
      continue
    fi

    # Already built but not active: offer to switch, defaulting to yes.
    if command "$vm" versions | command grep -q "$new"; then
      print -rn -- "$lang_name $new is already installed. Do you want to switch to it? [Y/n] "
      read -k1 -r choice
      [[ ! $choice =~ '^[Nn]$' ]] && command "$vm" global "$new"
      continue
    fi

    if ! command "$vm" install "$new" --skip-existing; then
      _lts_error "Failed to install $lang_name $new"
      return 1
    fi
    if ! command "$vm" global "$new"; then
      _lts_error "Failed to set $lang_name version to $new"
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
    _lts_error "Invalid arguments: $*"
    return 1
  fi

  local -a parts=(${(s/@/)1})
  local lang=${parts[1]}

  if ! _lts_validate_language "$lang"; then
    _lts_error "Invalid argument: $lang"
    return 1
  fi

  local version
  version=$(_lts_get_latest_version "$1") || return 1
  [[ -z $version ]] && return 1
  print -r -- "$version"
}

lts() {
  emulate -L zsh

  case $1 in
    install|i)
      _lts_install "${@:2}"
      ;;
    *)
      _lts_query "$@"
      ;;
  esac
}
