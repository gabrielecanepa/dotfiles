# Track npm global packages in $NPM_GLOBAL/package.json and reinstall them on demand.
#
# Usage: npm <command>

: ${NPM_GLOBAL:=$HOME/.npm}
export NPM_GLOBAL

# Newline-separated name@version list tracked in $NPM_GLOBAL/package.json.
_npm_global_saved_deps() {
  emulate -L zsh
  [[ -f $NPM_GLOBAL/package.json ]] || return 0
  command node -p \
    'const d=require(process.argv[1]).dependencies||{};Object.entries(d).map(([k,v])=>`${k}@${v}`).join("\n")' \
    "$NPM_GLOBAL/package.json" 2>/dev/null
}

# Rewrite $NPM_GLOBAL/package.json to mirror the installed globals as a
# {dependencies:{name:version}} manifest. Offline and atomic: the manifest is
# built from the installed set and moved into place, so a failure never corrupts
# the tracked file and a reader never sees a partial write.
_npm_global_dump() {
  emulate -L zsh
  local json tmp
  json="$(command npm list --global --depth=0 --json 2>/dev/null \
    | command node -p \
      'const d=JSON.parse(require("fs").readFileSync(0,"utf8")).dependencies||{};const o=Object.fromEntries(Object.entries(d).map(([k,v])=>[k,v.version]));Object.keys(o).length?JSON.stringify({dependencies:o},null,2):process.exit(1)' \
      2>/dev/null)" || return 1
  mkdir -p "$NPM_GLOBAL" || return 1
  tmp="$(mktemp "$NPM_GLOBAL/package.json.XXXXXX")" || return 1
  print -r -- "$json" > "$tmp" && command mv -f "$tmp" "$NPM_GLOBAL/package.json" && return 0
  rm -f "$tmp"
  return 1
}

npm() {
  emulate -L zsh

  case $1 in
    dump)
      if (( $# > 1 )); then
        print -r -- "npm-global: unknown arguments: ${*:2}" >&2
        print -r -- 'usage: npm dump' >&2
        return 1
      fi
      _npm_global_dump
      return $?
      ;;
    fresh)
      if (( $# > 1 )); then
        print -r -- "npm-global: unknown arguments: ${*:2}" >&2
        print -r -- 'usage: npm fresh' >&2
        return 1
      fi
      command npm update --global && _npm_global_dump
      return $?
      ;;
  esac

  # npm subcommand aliases that install packages.
  local -a install_commands=(
    install add i in ins inst insta instal isnt isnta isntal isntall
  )
  # Subcommands whose success should trigger a background package.json dump.
  local -a dump_commands=(
    $install_commands
    uninstall unlink remove rm r un
    update up upgrade udpate
  )
  # Long flags that consume the following token as their value, so that token
  # is not miscounted as a package name.
  local -a value_flags=(
    --prefix --registry --userconfig --globalconfig --cache --tag
    --omit --include --workspace -w --save-prefix --before --node-options
  )

  local tok cmd=''
  local -i global=0 skip_next=0 npkgs=0 seen_cmd=0
  for tok in "$@"; do
    # Skip the value token claimed by the previous value flag.
    if (( skip_next )); then
      skip_next=0
      continue
    fi
    # --global, or a combined short flag containing g (e.g. -gE).
    if [[ $tok == --global || ( $tok == -[^-]* && $tok == *g* ) ]]; then
      global=1
      continue
    fi
    if [[ $tok == -* ]]; then
      # Bare value flag (no =) consumes the next token; (Ie) is exact membership.
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

  # Non-global command, or one that only prints help: plain passthrough.
  if (( ! global )) || (( ${@[(Ie)-h]} || ${@[(Ie)--help]} )); then
    command npm "$@"
    return $?
  fi

  # Global install with no package named: reinstall everything tracked.
  if (( npkgs == 0 )) && (( ${install_commands[(Ie)$cmd]} )); then
    local -a deps
    deps=(${(f)"$(_npm_global_saved_deps)"})
    if (( ! ${#deps} )); then
      print -r -- "npm-global: no dependencies saved in $NPM_GLOBAL/package.json" >&2
      return 1
    fi
    command npm install --global "${deps[@]}"
    return $?
  fi

  command npm "$@"
  local exit=$?

  # Mutating global command succeeded: sync the tracked package.json before returning.
  if (( exit == 0 )) && (( ${dump_commands[(Ie)$cmd]} )); then
    _npm_global_dump || print -r -- 'npm-global: package.json sync failed' >&2
  fi

  return $exit
}
