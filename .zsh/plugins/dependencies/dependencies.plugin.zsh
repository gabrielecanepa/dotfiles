function dependencies() {
  local function get_package_root() {
    [[ -z "$1" ]] && echo $(pwd) && return 0
    [[ -d "$1" && -z "${@:2}" ]] && readlink -f "$1" && return 0
    [[ -f "$1" && "$(basename $1)" == "package.json" && -z "${@:2}" ]] && readlink -f "$(dirname "$1")" && return 0
    return 1
  }

  local args=()

  for arg in "$@"; do
    [[ $arg != "-l" ]] && args+=($arg) && continue
    local list=true
  done

  local absolute_path=$([[ ! -z "$args" && -f "$args" || -d "$args" ]] && readlink -f "$args" || echo "$args")

  local root
  root="$(get_package_root "$absolute_path")"
  [[ $? != 0 ]] && echo "Invalid path: $absolute_path" && return 1

  local dependencies="$(cat "$root/package.json" | jq -r '.dependencies | keys | .[]')"
  [[ $list == true ]] && echo "$(echo $dependencies | tr '\n' ' ')" || echo "$dependencies"
  return 0
}
