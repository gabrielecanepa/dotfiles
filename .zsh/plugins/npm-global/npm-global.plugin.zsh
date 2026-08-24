(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

: ${NPM_GLOBAL:=$HOME/.npm}
export NPM_GLOBAL

typeset -g _npm_global_dir="${0:A:h}"

_npm_global_saved_deps() {
  emulate -L zsh
  [[ -f $NPM_GLOBAL/package.json ]] || return 0
  command node -p \
    'const d=require(process.argv[1]).dependencies||{};Object.entries(d).map(([k,v])=>`${k}@${v}`).join("\n")' \
    "$NPM_GLOBAL/package.json" 2>/dev/null
}

# Dump into a temp file and move into place so a failure never corrupts the manifest.
_npm_global_dump() {
  emulate -L zsh
  local json tmp
  json="$(command npm list --global --depth=0 --json 2>/dev/null \
    | command node "$_npm_global_dir/dump.js" 2>/dev/null)" || return 1
  mkdir -p "$NPM_GLOBAL" || return 1
  tmp="$(mktemp "$NPM_GLOBAL/package.json.XXXXXX")" || return 1
  print -r -- "$json" > "$tmp" && command mv -f "$tmp" "$NPM_GLOBAL/package.json" && return 0
  rm -f "$tmp"
  return 1
}

_npm_global_drift() {
  emulate -L zsh
  [[ -f $NPM_GLOBAL/package.json ]] || return 0
  command node "$_npm_global_dir/drift.js" "$NPM_GLOBAL/package.json" 2>/dev/null
  return 0
}

npm() {
  emulate -L zsh

  case $1 in
    dump)
      if (( $# > 1 )); then
        _zsh::log error npm-global "unknown arguments: ${*:2}"
        print -ru2 -- 'usage: npm dump'
        return 1
      fi
      _npm_global_dump
      return $?
      ;;
    fresh)
      if (( $# > 1 )); then
        _zsh::log error npm-global "unknown arguments: ${*:2}"
        print -ru2 -- 'usage: npm fresh'
        return 1
      fi
      command npm update --global && _npm_global_dump
      return $?
      ;;
  esac

  local -a install_commands=(
    install add i in ins inst insta instal isnt isnta isntal isntall
  )
  local -a dump_commands=(
    $install_commands
    uninstall unlink remove rm r un
    update up upgrade udpate
  )
  local -a value_flags=(
    --prefix --registry --userconfig --globalconfig --cache --tag
    --omit --include --workspace -w --save-prefix --before --node-options
  )

  local tok cmd=''
  local -i global=0 skip_next=0 npkgs=0 seen_cmd=0
  for tok in "$@"; do
    if (( skip_next )); then
      skip_next=0
      continue
    fi
    if [[ $tok == --global || ( $tok == -[^-]* && $tok == *g* ) ]]; then
      global=1
      continue
    fi
    if [[ $tok == -* ]]; then
      if [[ $tok != *=* ]] && (( ${value_flags[(Ie)$tok]} )); then
        skip_next=1
      fi
      continue
    fi
    if (( seen_cmd )); then
      (( npkgs++ ))
    else
      cmd=$tok
      seen_cmd=1
    fi
  done

  if (( ! global )) || (( ${@[(Ie)-h]} || ${@[(Ie)--help]} )); then
    command npm "$@"
    return $?
  fi

  if (( npkgs == 0 )) && (( ${install_commands[(Ie)$cmd]} )); then
    local -a deps
    deps=(${(f)"$(_npm_global_saved_deps)"})
    if (( ! ${#deps} )); then
      _zsh::log error npm-global "no dependencies saved in $NPM_GLOBAL/package.json"
      return 1
    fi
    command npm install --global "${deps[@]}"
    return $?
  fi

  command npm "$@"
  local exit=$?

  if (( exit == 0 )) && (( ${dump_commands[(Ie)$cmd]} )); then
    _npm_global_dump || _zsh::log warn npm-global 'package.json sync failed'
  fi

  return $exit
}
