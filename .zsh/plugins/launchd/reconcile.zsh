#!/usr/bin/env zsh
#
# Reconcile user LaunchAgents from a source directory and track ownership in a state directory.
# Usage: zsh reconcile.zsh <source-directory> <state-directory>

emulate -LR zsh

_launchd_error() {
  print -ru2 -- "launchd: $1"
  return 1
}

_launchd_label_valid() {
  [[ $1 == [A-Za-z0-9]* && $1 != *[^A-Za-z0-9._-]* ]]
}

_launchd_loaded() {
  command launchctl print gui/$UID/$1 &>/dev/null
}

_launchd_unload() {
  if _launchd_loaded $1; then
    command launchctl bootout gui/$UID/$1 2>/dev/null || {
      _launchd_error "failed to unload $1"
      return 1
    }
  fi
}

_launchd_retire() {
  local label=$1 state=$2 destination=$3
  local owner=$state/owners/$label link=$destination/$label.plist
  local source=$(command readlink $owner)

  if [[ -e $link || -L $link ]]; then
    if [[ ! -L $link || $(command readlink $link) != $source ]]; then
      _launchd_error "refusing to retire $label: its LaunchAgents entry was replaced"
      return 1
    fi
  fi
  _launchd_unload $label || return 1
  if [[ -L $link ]]; then
    command rm -f $link || {
      _launchd_error "failed to remove $link"
      return 1
    }
  fi
  command rm -f $owner $state/loaded/$label.plist || {
    _launchd_error "failed to retire state for $label"
    return 1
  }
}

_launchd_reconcile() {
  local file=$1 state=$2 destination=$3
  local label=${file:t:r} source=${file:A} plist_label disabled
  local owner=$state/owners/$label link=$destination/$label.plist
  local snapshot=$state/loaded/$label.plist staged=$state/loaded/.$label.$$
  local owned=0 loaded=0

  if ! _launchd_label_valid $label || ! command plutil -lint -s $file &>/dev/null; then
    _launchd_error "invalid agent plist: $file"
    return 1
  fi
  if ! plist_label=$(command plutil -extract Label raw -expect string -o - $file 2>/dev/null) || [[ $plist_label != $label ]]; then
    _launchd_error "Label must be a string matching the filename stem: $file"
    return 1
  fi
  disabled=false
  if command plutil -type Disabled $file &>/dev/null; then
    if ! disabled=$(command plutil -extract Disabled raw -expect bool -o - $file 2>/dev/null); then
      _launchd_error "Disabled must be a boolean: $file"
      return 1
    fi
  fi
  [[ -L $owner ]] && owned=1
  if [[ -e $owner && ! -L $owner ]]; then
    _launchd_error "invalid ownership state for $label"
    return 1
  fi
  if [[ -e $link || -L $link ]]; then
    if [[ ! -L $link ]] || { (( ! owned )) && [[ $(command readlink $link) != $source ]]; }; then
      _launchd_error "refusing to replace unrelated LaunchAgents entry: $link"
      return 1
    fi
  fi
  _launchd_loaded $label && loaded=1
  if (( ! owned && loaded )); then
    _launchd_error "$label is already loaded outside this plugin"
    return 1
  fi

  if [[ ! -L $link || $(command readlink $link) != $source ]]; then
    command ln -sfn $source $link || {
      _launchd_error "failed to link $label"
      return 1
    }
  fi
  if [[ ! -L $owner || $(command readlink $owner) != $source ]]; then
    command ln -sfn $source $owner || {
      _launchd_error "failed to record ownership of $label"
      return 1
    }
  fi

  if [[ $disabled == true ]]; then
    _launchd_unload $label || return 1
    command rm -f $snapshot || {
      _launchd_error "failed to clear loaded state for $label"
      return 1
    }
    return 0
  fi
  if (( loaded )) && command cmp -s $file $snapshot; then
    return 0
  fi
  command cp $file $staged || {
    _launchd_error "failed to snapshot $label"
    return 1
  }
  if ! _launchd_unload $label; then
    command rm -f $staged
    return 1
  fi
  if ! command launchctl bootstrap gui/$UID $file 2>/dev/null; then
    command rm -f $staged
    _launchd_error "failed to load $label"
    return 1
  fi
  command mv -f $staged $snapshot || {
    _launchd_error "failed to record loaded definition of $label"
    return 1
  }
}

_launchd_main() {
  [[ $OSTYPE == darwin* ]] || return 0
  if (( $# != 2 )); then
    _launchd_error "expected a source directory and a state directory"
    return 1
  fi
  local dir=${1:A} state=${2:A} destination=~/Library/LaunchAgents
  local file owner label lockfd result=0
  [[ -d $dir ]] || return 0
  if [[ $dir == ${destination:A} ]]; then
    _launchd_error "source directory must differ from ~/Library/LaunchAgents"
    return 1
  fi

  umask 077
  command mkdir -p $state || {
    _launchd_error "failed to create state directory"
    return 1
  }
  zmodload zsh/system || {
    _launchd_error "zsh/system is required for reconciliation locking"
    return 1
  }
  : >> $state/.lock || {
    _launchd_error "failed to create reconciliation lock"
    return 1
  }
  zsystem flock -t 0 -f lockfd $state/.lock 2>/dev/null || return 0
  command mkdir -p $state/owners $state/loaded $destination || {
    _launchd_error "failed to create LaunchAgents or state directories"
    return 1
  }

  for owner in $state/owners/*(N); do
    label=${owner:t}
    if [[ ! -L $owner ]] || ! _launchd_label_valid $label; then
      _launchd_error "invalid ownership state: $owner"
      result=1
      continue
    fi
    [[ -e $dir/$label.plist ]] && continue
    _launchd_retire $label $state $destination || result=1
  done
  for file in $dir/*.plist(N); do
    _launchd_reconcile $file $state $destination || result=1
  done
  return $result
}

_launchd_main "$@"
