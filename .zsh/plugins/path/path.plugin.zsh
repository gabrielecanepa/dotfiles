#!/bin/zsh

function path() {
  for p in "${(s/:/)PATH}"; do
    echo $p
  done; unset p
}

function fpath() {
  for p in "${(s/:/)FPATH}"; do
    echo $p
  done; unset p
}
