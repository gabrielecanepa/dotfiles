#!/bin/zsh

function colors256() {
  for code in {000..255}; do
    print -nP -- "%F{$code}$code %f"
    [ $((${code} % 16)) -eq 15 ] && echo
  done
}
