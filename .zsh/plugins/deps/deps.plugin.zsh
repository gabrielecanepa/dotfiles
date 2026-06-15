function deps() {
  local function get_package_root() {
    [[ -z "$1" ]] && echo $(pwd) && return 0
    [[ -d "$1" && -z "${@:2}" ]] && readlink -f "$1" && return 0
    [[ -f "$1" && "$(basename $1)" == "package.json" && -z "${@:2}" ]] && readlink -f "$(dirname "$1")" && return 0
    return 1
  }

  local OPTS=(-L --list --dev --peer --optional --all)
  local args=($@)
  local dir=$(pwd)
  local opts=()
  local list=false
  local output=

  if [[ -f "$1" || -d "$1" ]]; then
    local dir="$(readlink "$1")"
    [[ $? != 0 ]] && echo "Invalid path: $1" && return 1
    args=(${@:2})
  fi

  for arg in $args; do
    if [[ ${OPTS[(r)$arg]} != $arg ]]; then
      echo "Invalid option: $arg"
      return 1
    fi
    if [[ $arg == "-L" || $arg == "--list" ]]; then
      list=true
      continue
    fi
    opts+=($arg)
  done

  root="$(get_package_root "$dir")"
  [[ $? != 0 ]] && echo "Invalid path: $dir" && return 1
  [[ ! -f "$root/package.json" ]] && echo "No package.json found" && return 1

  local package_json="$(cat "$root/package.json")"
  local deps="$(jq -r '.dependencies | keys[]' $package_json 2>/dev/null)"
  local dev_deps="$(jq -r '.devDependencies | keys[]' $package_json 2>/dev/null)"
  local peer_deps="$(jq -r '.peerDependencies | keys[]' $package_json  2>/dev/null)"
  local optional_deps="$(jq -r '.optionalDependencies | keys[]' $package_json  2>/dev/null)"

  if [[ ${#opts[@]} == 0 ]]; then
    local output="$deps"
  else
    for opt in $opts; do
      case $opt in
        --dev)
          [[ -z "$dev_deps" ]] && continue
          [[ -z "$output" ]] && output="$dev_deps" || output="$output\n$dev_deps"
          ;;
        --peer)
          [[ -z "$peer_deps" ]] && continue
          [[ -z "$output" ]] && output="$peer_deps" || output="$output\n$peer_deps"
          ;;
        --optional)
          [[ -z "$optional_deps" ]] && continue
          [[ -z "$output" ]] && output="$optional_deps" || output="$output\n$optional_deps"
          ;;
        --all)
          if [[ ${args[(r)--dev]} == --dev || ${args[(r)--peer]} == --peer || ${args[(r)--optional]} == --optional ]]; then
            echo "Can't specify --all with --dev, --peer or --optional"
            return 1
          fi
          for group in deps dev_deps peer_deps optional_deps; do
            [[ -z "${(P)group}" ]] && continue
            [[ -z "$output" ]] && output="${(P)group}" || output="$output\n${(P)group}"
          done
          ;;
      esac
    done
  fi

  [[ -z "$output" ]] && return 0
  local output_list="$(echo $output | tr '\n' ' ')"
  [[ $list == true ]] && echo $output_list || echo $output
}
