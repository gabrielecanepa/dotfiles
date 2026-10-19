typeset -g _defaults_settings_file=${0:A:h}/settings.txt

_defaults_parse() {
  emulate -L zsh
  local line=$1
  local -a words
  words=(${(z)line})
  (( $#words )) || return 1
  [[ $words[1] == defaults ]] || return 1
  local i=2
  reply_host=()
  if [[ $words[2] == -currentHost ]]; then
    reply_host=(-currentHost)
    i=3
  fi
  [[ $words[i] == write ]] || return 1
  (( $#words == i + 4 )) || return 1
  [[ $words[i+3] == -(bool|int|float|string) ]] || return 1
  [[ $words[i+4] != *'$'* ]] || return 1
  reply_domain=$words[i+1]
  reply_key=$words[i+2]
  reply_flag=$words[i+3]
  reply_value=$words[i+4]
  return 0
}

_defaults_parse_setting() {
  emulate -L zsh
  local line=$1
  local -a words
  words=(${(z)line})
  (( $#words )) || return 1
  local i=1
  reply_host=()
  if [[ $words[1] == -currentHost ]]; then
    reply_host=(-currentHost)
    i=2
  fi
  (( $#words == i + 2 )) || return 1
  [[ $words[i+2] == -(bool|int|float|string) ]] || return 1
  reply_domain=$words[i]
  reply_key=$words[i+1]
  reply_flag=$words[i+2]
  return 0
}

_defaults_format() {
  emulate -L zsh
  local flag=$1 live=$2
  case $flag in
    -bool) [[ $live == 1 ]] && print -r -- true || print -r -- false ;;
    -float) print -r -- ${live%.0} ;;
    -string)
      if [[ $live == $HOME/* ]]; then
        local relative=${live#$HOME/}
        relative=${relative//\\/\\\\}
        relative=${relative//\"/\\\"}
        relative=${relative//\$/\\\$}
        relative=${relative//\`/\\\`}
        print -r -- '"$HOME/'$relative'"'
      else
        print -r -- ${(q-)live}
      fi
      ;;
    *) print -r -- "$live" ;;
  esac
}

_defaults_dump() {
  emulate -L zsh
  local dry=$1 file=$2 tmp='' line mode live formatted new source=$file seed=''
  local -a reply_host
  local reply_domain reply_key reply_flag reply_value
  trap 'command rm -f "$tmp"' EXIT INT TERM
  if [[ ! -s $file ]]; then
    source=$_defaults_settings_file
    seed=seed
  fi
  if [[ ! -r $source ]]; then
    print -ru2 -- "defaults: settings missing at ${source/#$HOME/~}"
    return 1
  fi
  if [[ ! -d ${file:h} ]]; then
    if [[ $dry == dry ]]; then
      tmp=$(command mktemp ${TMPDIR:-/tmp}/${file:t}.XXXXXX) || return 1
    else
      command mkdir -p ${file:h} || return 1
    fi
  fi
  [[ -n $tmp ]] || tmp=$(command mktemp ${file:h}/.${file:t}.XXXXXX) || return 1
  mode=$(command stat -f '%Lp' $file 2>/dev/null)
  command chmod ${mode:-644} $tmp
  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $seed == seed ]]; then
      _defaults_parse_setting "$line" || continue
      if live=$(command defaults $reply_host read ${(Q)reply_domain} ${(Q)reply_key} 2>/dev/null); then
        formatted=$(_defaults_format "$reply_flag" "$live")
        print -r -- "defaults${reply_host:+ -currentHost} write $reply_domain $reply_key $reply_flag $formatted"
      fi
      continue
    fi
    new=$line
    if _defaults_parse "$line"; then
      if live=$(command defaults $reply_host read ${(Q)reply_domain} ${(Q)reply_key} 2>/dev/null); then
        formatted=$(_defaults_format "$reply_flag" "$live")
        new="defaults${reply_host:+ -currentHost} write $reply_domain $reply_key $reply_flag $formatted"
      fi
    fi
    print -r -- "$new"
  done < $source > $tmp
  if [[ -e $file ]] && command cmp -s $file $tmp; then
    command rm -f $tmp
    print -r -- 'No changes'
    return 0
  fi
  if [[ $dry == dry ]]; then
    local tracked=$file
    [[ -e $tracked ]] || tracked=/dev/null
    command diff -u --label 'config (tracked)' --label 'config (live)' $tracked $tmp
    command rm -f $tmp
  else
    command mv -f $tmp $file || return 1
    print -r -- 'Updated config'
  fi
  return 0
}

_defaults_load() {
  emulate -L zsh
  [[ $(command uname) == Darwin ]] || return 0
  local file=$1
  command bash -euo pipefail $file || {
    print -ru2 -- 'defaults: failed to apply config'
    return 1
  }
  command killall Dock Finder ControlCenter SystemUIServer 2>/dev/null
  return 0
}

_defaults_list() {
  emulate -L zsh
  command grep -E '^[[:space:]]*defaults( -currentHost)? write ' "$1"
}

defaults() {
  emulate -L zsh

  local cmd=${1-}
  case $cmd in
    dump | load | list) shift ;;
    *)
      command defaults "$@"
      return $?
      ;;
  esac

  local dry=''
  if [[ $cmd == dump ]]; then
    if (( $# )); then
      if (( $# == 1 )) && [[ $1 == --dry-run ]]; then
        dry=dry
      else
        print -ru2 -- 'Usage: defaults dump [--dry-run]'
        return 1
      fi
    fi
  elif (( $# )); then
    print -ru2 -- "Usage: defaults $cmd"
    return 1
  fi

  local file=${MACOS_DEFAULTS:-${XDG_CONFIG_HOME:-~/.config}/macos/defaults.sh}
  if [[ $cmd != dump && ! -r $file ]]; then
    print -ru2 -- "defaults: config missing at ${file/#$HOME/~}"
    return 1
  fi

  case $cmd in
    dump) _defaults_dump "$dry" "$file" ;;
    load) _defaults_load $file ;;
    list) _defaults_list $file ;;
  esac
}

if (( $+functions[compdef] )); then
  compdef _defaults defaults
fi
