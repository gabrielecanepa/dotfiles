: ${NPM_GLOBAL_DIR:=~/.npm}

typeset -g _npm_global_dir=${0:A:h}

_npm_global_deps() {
  emulate -L zsh
  [[ -f $NPM_GLOBAL_DIR/package.json ]] || return 0
  command node -p \
    'const d=require(process.argv[1]).dependencies||{};Object.entries(d).map(([k,v])=>`${k}@${v}`).join("\n")' \
    $NPM_GLOBAL_DIR/package.json 2>/dev/null
}

_npm_global_dump() {
  emulate -L zsh
  setopt pipefail
  local json tmp
  json=$(command npm list --global --depth=0 --json 2>/dev/null \
    | command node $_npm_global_dir/dump.js 2>/dev/null) || return 1
  mkdir -p $NPM_GLOBAL_DIR || return 1
  tmp=$(mktemp $NPM_GLOBAL_DIR/package.json.XXXXXX) || return 1
  print -r -- "$json" > $tmp && command mv -f $tmp $NPM_GLOBAL_DIR/package.json && return 0
  rm -f $tmp
  return 1
}

_npm_global_rehash() {
  emulate -L zsh
  (( $+commands[nodenv] )) || return 0
  command nodenv rehash
}

npm() {
  emulate -L zsh

  case $1 in
    dump)
      if (( $# > 1 )); then
        print -ru2 -- "npm: unknown arguments: ${*:2}"
        print -ru2 -- 'Usage: npm dump'
        return 1
      fi
      _npm_global_dump
      return $?
      ;;
    fresh)
      local -i interactive=0
      if (( $# > 1 )); then
        if (( $# == 2 )) && [[ $2 == -i || $2 == --interactive ]]; then
          interactive=1
        else
          print -ru2 -- "npm: unknown arguments: ${*:2}"
          print -ru2 -- 'Usage: npm fresh [-i]'
          return 1
        fi
      fi
      if (( interactive )); then
        command npx --yes --loglevel=warn taze major -g -I -i || return $?
      else
        command npm update --global || return $?
      fi
      _npm_global_rehash
      _npm_global_dump
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
    --omit --include --workspace -w --save-prefix --before --node-options --location
  )
  local -a args=("$@")

  local tok cmd=''
  local -i global=0 skip_next=0 npkgs=0 cmd_index=0 i
  for (( i = 1; i <= ${#args}; i++ )); do
    tok=$args[$i]
    if (( skip_next )); then
      skip_next=0
      continue
    fi
    case $tok in
      --global|--global=true) global=1 ;;
      --location=global) global=1 ;;
      --location) [[ $args[$(( i + 1 ))] == global ]] && global=1 ;;
      -*) [[ $tok != --* && $tok == *g* ]] && global=1 ;;
    esac
    if [[ $tok != *=* ]] && (( ${value_flags[(Ie)$tok]} )); then
      skip_next=1
      continue
    fi
    if [[ -z $cmd ]] && (( ${dump_commands[(Ie)$tok]} )); then
      cmd=$tok
      cmd_index=$i
    fi
  done

  skip_next=0
  for (( i = cmd_index + 1; cmd_index && i <= ${#args}; i++ )); do
    tok=$args[$i]
    if (( skip_next )); then
      skip_next=0
      continue
    fi
    if [[ $tok == -- ]]; then
      (( npkgs += ${#args} - i ))
      break
    fi
    if [[ $tok == -* ]]; then
      if [[ $tok != *=* ]] && (( ${value_flags[(Ie)$tok]} )); then
        skip_next=1
      fi
      continue
    fi
    (( npkgs++ ))
  done

  if (( ! global )) || (( ${@[(Ie)-h]} || ${@[(Ie)--help]} )); then
    command npm "$@"
    return $?
  fi

  if (( npkgs == 0 )) && (( ${install_commands[(Ie)$cmd]} )); then
    local -a deps
    deps=(${(f)"$(_npm_global_deps)"})
    if (( ! ${#deps} )); then
      print -ru2 -- "npm: no dependencies saved in $NPM_GLOBAL_DIR/package.json"
      return 1
    fi
    command npm install --global "${deps[@]}" || return $?
    _npm_global_rehash
    return 0
  fi

  command npm "$@"
  local exit=$?

  if (( exit == 0 )) && (( ${dump_commands[(Ie)$cmd]} )); then
    _npm_global_rehash
    _npm_global_dump || print -ru2 -- 'npm-global: package.json sync failed'
  fi

  return $exit
}

_npm_completions() {
  local -a custom_commands=(
    dump
    fresh
  )

  if (( CURRENT == 2 )); then
    compadd -Q -- $custom_commands
  fi
  if (( CURRENT > 2 )) && [[ $words[2] == dump ]]; then
    return 0
  fi
  if (( CURRENT > 2 )) && [[ $words[2] == fresh ]]; then
    compadd -Q -- -i --interactive
    return 0
  fi

  local -a native_commands
  native_commands=(${(f)"$(COMP_CWORD=$((CURRENT - 1)) \
    COMP_LINE=$BUFFER \
    COMP_POINT=${#BUFFER} \
    command npm completion -- "${words[@]}" 2>/dev/null)"})
  compadd -Q -- $native_commands
}

if (( $+functions[compdef] )); then
  compdef _npm_completions npm
fi
