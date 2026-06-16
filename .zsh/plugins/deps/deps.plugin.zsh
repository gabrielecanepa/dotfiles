# Print the dependencies declared in a project's package.json.
#
# Usage: deps [<dir>|<path/to/package.json>] [-L|--list] [--dev|--peer|--optional|--all]

# Resolve an input to the directory holding package.json: a dir, a package.json path, or empty for PWD. Return 1 otherwise.
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

  # $+commands[jq] is the membership test for jq on PATH.
  if (( ! $+commands[jq] )); then
    print -ru2 -- 'deps: jq is required but not installed'
    return 1
  fi

  local -a opts_allowed=(-L --list --dev --peer --optional --all)
  local -a args=("$@")
  local dir=$PWD
  local -a groups
  local list=0

  # First positional may be a path; if so, take it as the root and drop it from the options.
  if [[ -f $1 || -d $1 ]]; then
    dir=${1:A}
    args=("${@:2}")
  fi

  local arg
  for arg in "${args[@]}"; do
    # (Ie) yields the index of an exact match; zero means $arg is not a known option.
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
        # --all is exclusive: reject it alongside any per-group flag.
        if (( ${args[(Ie)--dev]} || ${args[(Ie)--peer]} || ${args[(Ie)--optional]} )); then
          print -ru2 -- "deps: can't specify --all with --dev, --peer or --optional"
          return 1
        fi
        groups=(dependencies devDependencies peerDependencies optionalDependencies)
        ;;
    esac
  done

  local root
  root=$(_deps_get_package_root "$dir") || { print -ru2 -- "deps: invalid path: $dir"; return 1; }
  [[ -f $root/package.json ]] || { print -ru2 -- 'deps: no package.json found'; return 1; }

  (( ${#groups} )) || groups=(dependencies)

  local -a out
  local group name
  for group in "${groups[@]}"; do
    # (f) splits jq's output on newlines, one dependency name per element.
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
