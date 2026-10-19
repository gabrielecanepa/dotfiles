_deps_get_package_root() {
  emulate -L zsh
  local target=$1
  [[ -z $target ]] && { print -r -- $PWD; return 0; }
  [[ -d $target ]] && { print -r -- ${target:A}; return 0; }
  [[ -f $target && ${target:t} == package.json ]] && { print -r -- ${target:h:A}; return 0; }
  return 1
}

deps() {
  emulate -L zsh

  if (( ! $+commands[jq] )); then
    print -ru2 -- 'deps: jq is required but not installed'
    return 1
  fi

  local -a opts_allowed=(-L --list --dev --peer --optional --all)
  local -a args=("$@")
  local dir=$PWD
  local -a groups
  local list=0

  if [[ -f $1 || -d $1 ]]; then
    dir=${1:A}
    args=("${@:2}")
  fi

  local arg
  for arg in "${args[@]}"; do
    if (( ! ${opts_allowed[(Ie)$arg]} )); then
      print -ru2 -- "deps: invalid option: $arg"
      return 1
    fi
    case $arg in
      -L|--list) list=1 ;;
      --dev) (( ${groups[(Ie)devDependencies]} )) || groups+=(devDependencies) ;;
      --peer) (( ${groups[(Ie)peerDependencies]} )) || groups+=(peerDependencies) ;;
      --optional) (( ${groups[(Ie)optionalDependencies]} )) || groups+=(optionalDependencies) ;;
      --all)
        if (( ${args[(Ie)--dev]} || ${args[(Ie)--peer]} || ${args[(Ie)--optional]} )); then
          print -ru2 -- "deps: cannot specify --all with --dev, --peer or --optional"
          return 1
        fi
        groups=(dependencies devDependencies peerDependencies optionalDependencies)
        ;;
    esac
  done

  local root
  root=$(_deps_get_package_root $dir) || { print -ru2 -- "deps: invalid path: $dir"; return 1; }
  [[ -f $root/package.json ]] || { print -ru2 -- 'deps: no package.json found'; return 1; }

  (( ${#groups} )) || groups=(dependencies)

  local output
  output=$(command jq -r --arg groups ${(j:,:)groups} \
    '($groups | split(",")) as $groups | [$groups[] as $group | (.[$group] // {}) | keys[]] | unique[]' \
    $root/package.json 2>/dev/null) || {
    print -ru2 -- "deps: invalid package.json: $root/package.json"
    return 1
  }

  local -a out
  [[ -n $output ]] && out=("${(@f)output}")

  (( ${#out} )) || return 0

  if (( list )); then
    print -r -- "${out[*]}"
  else
    print -rl -- "${out[@]}"
  fi
}
