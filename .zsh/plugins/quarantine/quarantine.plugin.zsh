if ((! ${+_QUARANTINE_STATE_DIR})); then
  typeset -gr _QUARANTINE_STATE_DIR=${XDG_STATE_HOME:-~/.local/state}/quarantine
fi

_quarantine_path() {
  emulate -L zsh
  REPLY=${1:A}
}

_quarantine_record() {
  emulate -L zsh
  local target=$1 digest
  digest=$(command md5 -qs $target) || return 1
  REPLY=$_QUARANTINE_STATE_DIR/$digest
}

_quarantine_value() {
  emulate -L zsh
  local target=$1 attrs
  local -a names

  if [[ ! -e $target && ! -L $target ]]; then
    print -ru2 -- "quarantine: path not found: $target"
    return 2
  fi
  if ! attrs=$(command xattr $target 2>/dev/null); then
    print -ru2 -- "quarantine: cannot read attributes: $target"
    return 2
  fi
  names=("${(@f)attrs}")
  ((${names[(Ie)com.apple.quarantine]})) || return 1
  if ! REPLY=$(command xattr -px com.apple.quarantine $target 2>/dev/null); then
    print -ru2 -- "quarantine: cannot read quarantine attribute: $target"
    return 2
  fi
  return 0
}

_quarantine_backup() {
  emulate -L zsh
  local target=$1 value=$2 record tmp saved

  _quarantine_record $target || return 1
  record=$REPLY
  if [[ -d $record ]]; then
    if [[ ! -r $record/path || ! -r $record/value ]]; then
      print -ru2 -- "quarantine: invalid backup for $target"
      return 1
    fi
    saved=$(<$record/path)
    if [[ $saved != $target ]]; then
      print -ru2 -- "quarantine: backup collision for $target"
      return 1
    fi
    return 0
  fi

  command mkdir -p $_QUARANTINE_STATE_DIR || return 1
  command chmod 700 $_QUARANTINE_STATE_DIR || return 1
  tmp=$record.tmp.$$.$RANDOM
  command mkdir $tmp || return 1
  command chmod 700 $tmp || {
    command rmdir $tmp
    return 1
  }
  if ! print -rn -- $target >$tmp/path || ! print -rn -- "$value" >$tmp/value; then
    command rm -f $tmp/path $tmp/value
    command rmdir $tmp
    return 1
  fi
  command chmod 600 $tmp/path $tmp/value || {
    command rm -f $tmp/path $tmp/value
    command rmdir $tmp
    return 1
  }
  if ! command mv $tmp $record; then
    command rm -f $tmp/path $tmp/value
    command rmdir $tmp
    return 1
  fi
}

_quarantine_backup_value() {
  emulate -L zsh
  local target=$1 record saved

  _quarantine_record $target || return 2
  record=$REPLY
  [[ -d $record ]] || return 1
  if [[ ! -r $record/path || ! -r $record/value ]]; then
    print -ru2 -- "quarantine: invalid backup for $target"
    return 2
  fi
  saved=$(<$record/path)
  if [[ $saved != $target ]]; then
    print -ru2 -- "quarantine: backup collision for $target"
    return 2
  fi
  REPLY=$(<$record/value)
  return 0
}

_quarantine_for_each() {
  emulate -L zsh
  local operation=$1 recursive=$2 input=$3 root target
  local -a targets
  integer changed=0 failed=0 result

  _quarantine_path "$input"
  root=$REPLY
  targets=($root)
  if ((recursive)) && [[ -d $root ]]; then
    targets+=($root/**/*(DN))
  fi

  for target in "${targets[@]}"; do
    $operation $target
    result=$?
    ((result == 0)) && ((changed++))
    ((result == 2)) && failed=1
  done

  if ((! changed && ! failed)); then
    if [[ $operation == _quarantine_remove ]]; then
      print -r -- "$input: not quarantined"
    else
      print -r -- "$input: not removed"
    fi
  fi
  ((failed == 0))
}

_quarantine_remove() {
  emulate -L zsh
  local target=$1 value result

  _quarantine_value $target
  result=$?
  ((result == 0)) || return $result
  value=$REPLY
  _quarantine_backup $target "$value" || return 2
  if ! command xattr -d com.apple.quarantine $target 2>/dev/null; then
    print -ru2 -- "quarantine: cannot remove quarantine attribute: $target"
    return 2
  fi
  print -r -- "$target: removed"
  return 0
}

_quarantine_restore() {
  emulate -L zsh
  local target=$1 value record result

  _quarantine_backup_value $target
  result=$?
  ((result == 0)) || return $result
  value=$REPLY
  _quarantine_record $target || return 2
  record=$REPLY
  if ! command xattr -wx com.apple.quarantine "$value" $target 2>/dev/null; then
    print -ru2 -- "quarantine: cannot restore quarantine attribute: $target"
    return 2
  fi
  if ! command rm -f $record/path $record/value || ! command rmdir $record; then
    print -ru2 -- "quarantine: cannot remove backup for $target"
    return 2
  fi
  print -r -- "$target: restored"
  return 0
}

_quarantine_status() {
  emulate -L zsh
  local input=$1 verbose=$2 target raw result

  _quarantine_path "$input"
  target=$REPLY
  _quarantine_value $target
  result=$?
  if ((result == 0)); then
    print -r -- "$input: quarantined"
    if ((verbose)); then
      raw=$(command xattr -p com.apple.quarantine $target) || return 1
      print -r -- "$raw"
    fi
    return 0
  fi
  ((result == 1)) || return 1

  _quarantine_backup_value $target
  result=$?
  if ((result == 0)); then
    print -r -- "$input: removed"
    if ((verbose)); then
      print -rn -- "$REPLY" | command xxd -r -p
      print
    fi
    return 0
  fi
  ((result == 1)) || return 1
  print -r -- "$input: not quarantined"
}

_quarantine_help() {
  print -r -- 'Usage: quarantine <command>'
  print
  print -r -- 'Commands:'
  print -r -- '  status [-v] <path>...          Print quarantine status.'
  print -r -- '  remove [-r] <path>...          Remove and save quarantine attributes.'
  print -r -- '  restore [-r] <path>...         Restore saved quarantine attributes.'
  print -r -- '  set <raw-value> <path>          Set a quarantine attribute.'
  print -r -- '  help                            Show this message.'
}

quarantine() {
  emulate -L zsh
  local cmd=${1-} raw target
  local -a paths
  integer recursive=0 verbose=0 rc=0
  (($#)) && shift

  case $cmd in
    status)
      while (($#)); do
        case $1 in
          -v | --verbose)
            verbose=1
            shift
            ;;
          -*)
            print -ru2 -- "quarantine: unknown option: $1"
            return 1
            ;;
          *)
            paths+=("$1")
            shift
            ;;
        esac
      done
      if ((! ${#paths})); then
        print -ru2 -- 'Usage: quarantine status [-v] <path>...'
        return 1
      fi
      for target in "${paths[@]}"; do
        _quarantine_status "$target" $verbose || rc=1
      done
      return $rc
      ;;
    remove | restore)
      while (($#)); do
        case $1 in
          -r | --recursive)
            recursive=1
            shift
            ;;
          -*)
            print -ru2 -- "quarantine: unknown option: $1"
            return 1
            ;;
          *)
            paths+=("$1")
            shift
            ;;
        esac
      done
      if ((! ${#paths})); then
        print -ru2 -- "Usage: quarantine $cmd [-r] <path>..."
        return 1
      fi
      for target in "${paths[@]}"; do
        _quarantine_for_each _quarantine_$cmd $recursive "$target" || rc=1
      done
      return $rc
      ;;
    set)
      if (($# != 2)); then
        print -ru2 -- 'Usage: quarantine set <raw-value> <path>'
        return 1
      fi
      raw=$1
      _quarantine_path "$2"
      target=$REPLY
      if [[ ! -e $target && ! -L $target ]]; then
        print -ru2 -- "quarantine: path not found: $2"
        return 1
      fi
      if ! command xattr -w com.apple.quarantine "$raw" $target 2>/dev/null; then
        print -ru2 -- "quarantine: cannot set quarantine attribute: $2"
        return 1
      fi
      print -r -- "$2: quarantined"
      ;;
    help | -h | --help | '')
      _quarantine_help
      ;;
    *)
      print -ru2 -- "quarantine: unknown command: $cmd"
      print -ru2
      _quarantine_help >&2
      return 1
      ;;
  esac
}

if (($+functions[compdef])); then
  compdef _quarantine quarantine
fi
