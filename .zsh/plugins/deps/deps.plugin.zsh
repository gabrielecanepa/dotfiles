(( $+functions[_zsh::log] )) || _zsh::log() { print -ru2 -- "$2: $3" }

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
    _zsh::log error deps 'jq is required but not installed'
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
      _zsh::log error deps "invalid option: $arg"
      return 1
    fi
    case $arg in
      -L|--list) list=1 ;;
      --dev) (( ${groups[(Ie)devDependencies]} )) || groups+=(devDependencies) ;;
      --peer) (( ${groups[(Ie)peerDependencies]} )) || groups+=(peerDependencies) ;;
      --optional) (( ${groups[(Ie)optionalDependencies]} )) || groups+=(optionalDependencies) ;;
      --all)
        if (( ${args[(Ie)--dev]} || ${args[(Ie)--peer]} || ${args[(Ie)--optional]} )); then
          _zsh::log error deps "can't specify --all with --dev, --peer or --optional"
          return 1
        fi
        groups=(dependencies devDependencies peerDependencies optionalDependencies)
        ;;
    esac
  done

  local root
  root=$(_deps_get_package_root "$dir") || { _zsh::log error deps "invalid path: $dir"; return 1; }
  [[ -f $root/package.json ]] || { _zsh::log error deps 'no package.json found'; return 1; }

  (( ${#groups} )) || groups=(dependencies)

  local -a out
  local group name
  for group in "${groups[@]}"; do
    for name in ${(f)"$(command jq -r "(.${group} // {}) | keys[]" "$root/package.json" 2>/dev/null)"}; do
      out+=("$name")
    done
  done

  (( ${#out} )) || return 0

  if (( list )); then
    print -r -- "${out[*]}"
  else
    print -rl -- "${out[@]}"
  fi
}
