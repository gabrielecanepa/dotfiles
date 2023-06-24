#!/bin/zsh

function node-modules() {
  local _cut="\r\033[1A\033[0K"
  local _cmd=$1
  local _path=$(realpath ${2:-.})

  local function validate_path() {
    [[ -z "$_path" ]] && echo "${fg[red]}Error: you must specify a valid directory$reset_color" && return 1
    [[ ! -d "$_path" ]] && echo "${fg[red]}Error: $_path is not a valid directory$reset_color" && return 1
    return 0
  }

  case $1 in
    list)
      ! validate_path && return 1
      echo "Looking for modules inside $_path..."
      local node_modules=$(find "$_path" -name "node_modules" -type d -prune -print | xargs du -chs | sort -hr)
      [[ -n "$node_modules" ]] && echo "$_cut$node_modules" || echo "${_cut}Can't find any modules in $_path"
      ;;

    clear)
      ! validate_path && return 1
      echo "Looking for modules inside $_path..."
      local node_modules_count=$(find $_path -name "node_modules" -type d -prune | grep -c /)
      if [[ $node_modules_count -gt 0 ]]; then
        echo "$_cut${fg[yellow]}WARNING: this will permanently delete the node_modules folder from $node_modules_count project$([[ $node_modules_count -gt 1 ]] && echo s)$reset_color"
        printf "Are you sure you want to continue? (y/N) "
        read -r _choice
        if [[ $_choice =~ [yY] ]]; then
          find $_path -name "node_modules" -type d -prune -exec rm -rf '{}' +
          echo "${fg[green]}$([[ $node_modules_count -gt 1 ]] && echo "$node_modules_count ")node_modules folder$([[ $node_modules_count -gt 1 ]] && echo s) successfully deleted$reset_color"
        fi
        unset _choice
      else
        echo "${_cut}Can't find any modules in $_path"
      fi
      ;;

    help|-h|--help)
      echo "Usage: $funcstack[1] <command> [path]"
      echo
      echo "Commands:"
      echo -e "  list\t	List all node_modules folders in the specified path"
      echo -e "  clear\t	Permanently delete all node_modules folders in the specified path"
      echo -e "  help\t	Show this help message"
      ;;

    *)
      [[ -n $_cmd ]] && echo "${fg[red]}Unknown command: $_cmd$reset_color" && echo
      eval $funcstack[1] --help
      ;;
  esac
}
