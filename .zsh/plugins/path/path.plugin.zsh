#!/bin/zsh

function path() {
  if [[ ! -z "$@" ]]; then
    echo "Unknown option: $@"
    return 1
  fi

  for p in "${(s/:/)PATH}"; do
    echo $p
  done

  unset p
}
