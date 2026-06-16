# Track npm global packages in $NPM_GLOBAL/package.json and reinstall them on demand.
#
# Usage: npm <command>

: ${NPM_GLOBAL:=$HOME/.npm}
export NPM_GLOBAL

# Space-separated list of every global dependency npm currently has installed.
_npm_global_deps() {
  emulate -L zsh
  command npm list -g --depth=0 \
    | sed -e '1d' -e 's/^[^ ]* //' -e 's/ ->.*$//' \
    | tr '\n' ' ' \
    | sed 's/[[:space:]]*$//'
}

# Newline-separated name@version list tracked in $NPM_GLOBAL/package.json.
_npm_global_saved_deps() {
  emulate -L zsh
  [[ -f $NPM_GLOBAL/package.json ]] || return 0
  command node -p \
    'const d=require(process.argv[1]).dependencies||{};Object.entries(d).map(([k,v])=>`${k}@${v}`).join("\n")' \
    "$NPM_GLOBAL/package.json" 2>/dev/null
}

# Rewrite $NPM_GLOBAL/package.json to mirror the installed globals (lock only).
npm-dump() {
  emulate -L zsh
  if (( $# )); then
    print -r -- "Unknown arguments: $*"
    print
    print -r -- "To dump global dependencies, run:"
    print -r -- "  npm dump"
    return 1
  fi
  (
    cd "$NPM_GLOBAL" || exit 1
    print -r -- '{}' > package.json
    local -a deps
    deps=(${(z)"$(_npm_global_deps)"})
    command npm install "${deps[@]}" --package-lock-only
    local rc=$?
    rm -rf node_modules
    return $rc
  )
}

# Update every global dependency, then refresh the tracked package.json.
npm-fresh() {
  emulate -L zsh
  if (( $# )); then
    print -r -- "Unknown arguments: $*"
    print
    print -r -- "To update all global dependencies, run:"
    print -r -- "  npm fresh"
    return 1
  fi
  command npm -g update
  local rc=$?
  # Detached background dump so the prompt returns immediately.
  ( ( npm-dump ) &>/dev/null & ) &>/dev/null
  return $rc
}

npm() {
  emulate -L zsh
  mkdir -p "$NPM_GLOBAL"

  # npm subcommand aliases that install packages.
  local -a install_commands=(
    install add i in ins inst insta instal isnt isntal isntall
  )
  # Subcommands whose success should trigger a background package.json dump.
  local -a dump_commands=(
    $install_commands
    uninstall unlink remove rm r
    un update up upgrade udpate
  )
  # Long flags that consume the following token as their value, so that token
  # is not miscounted as a package name.
  local -a value_flags=(
    --prefix --registry --userconfig --globalconfig --cache --tag
    --omit --include --workspace -w --save-prefix --before --node-options
  )

  local tok cmd=""
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

  if (( ! global )); then
    case $1 in
      dump|fresh)
        npm-$1 "${@:2}"
        ;;
      *)
        command npm "$@"
        ;;
    esac
    return $?
  fi

  # Global install with no package named: reinstall everything tracked.
  if (( npkgs == 0 )) && (( ${install_commands[(Ie)$cmd]} )); then
    local -a deps
    deps=(${(f)"$(_npm_global_saved_deps)"})
    if (( ${#deps} == 0 )); then
      print -ru2 -- "No global dependencies tracked in $NPM_GLOBAL/package.json"
      return 1
    fi
    command npm install --global "${deps[@]}"
    return $?
  fi

  command npm "$@"
  local rc=$?

  # Mutating global command succeeded: dump the new state in the background.
  if (( rc == 0 )) && (( ${dump_commands[(Ie)$cmd]} )); then
    ( ( npm-dump ) &>/dev/null & ) &>/dev/null
  fi

  return $rc
}

nodenv() {
  emulate -L zsh
  command nodenv "$@"
  local rc=$?

  # A fresh Node version starts with no globals; reinstall and dump them.
  if [[ $1 == install ]]; then
    local -a deps
    deps=(${(z)"$(_npm_global_deps)"})
    (
      (
        command npm install "${deps[@]}" --global && npm-dump
      ) &>/dev/null &
    ) &>/dev/null
  fi

  return $rc
}
