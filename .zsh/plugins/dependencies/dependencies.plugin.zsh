function dependencies() {
  local function get_package_root() {
    [[ -z "$1" ]] && echo $(pwd) && return 0
    [[ -d "$1" && -z "${@:2}" ]] && readlink -f "$1" && return 0
    [[ -f "$1" && "$(basename $1)" == "package.json" && -z "${@:2}" ]] && readlink -f "$(dirname "$1")" && return 0
    return 1
  }

  local OPTS=(-L --dev --peer --optional --all)
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
    [[ $arg == "-L" ]] && list=true && continue
    opts+=($arg)
  done

  root="$(get_package_root "$dir")"
  [[ $? != 0 ]] && echo "Invalid path: $dir" && return 1
  [[ ! -f "$root/package.json" ]] && echo "No package.json found." && return 1

  local dependencies="$(cat "$root/package.json" | jq -r '.dependencies | keys | .[]' 2>/dev/null)"
  local dev_dependencies="$(cat "$root/package.json" | jq -r '.devDependencies | keys | .[]' 2>/dev/null)"
  local peer_dependencies="$(cat "$root/package.json" | jq -r '.peerDependencies | keys | .[]' 2>/dev/null)"
  local optional_dependencies="$(cat "$root/package.json" | jq -r '.optionalDependencies | keys | .[]' 2>/dev/null)"

  if [[ ${#opts[@]} == 0 ]]; then
    local output="$dependencies"
  else
    for opt in $opts; do
      case $opt in
        --dev)
          [[ -z "$dev_dependencies" ]] && continue
          [[ -z "$output" ]] && output="$dev_dependencies" || output="$output\n$dev_dependencies"
          ;;
        --peer)
          [[ -z "$peer_dependencies" ]] && continue
          [[ -z "$output" ]] && output="$peer_dependencies" || output="$output\n$peer_dependencies"
          ;;
        --optional)
          [[ -z "$optional_dependencies" ]] && continue
          [[ -z "$output" ]] && output="$optional_dependencies" || output="$output\n$optional_dependencies"
          ;;
        --all)
          if [[ ${args[(r)--dev]} == --dev || ${args[(r)--peer]} == --peer || ${args[(r)--optional]} == --optional ]]; then
            echo "Can't specify --all with --dev, --peer or --optional"
            return 1
          fi
          for group in dependencies dev_dependencies peer_dependencies optional_dependencies; do
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
