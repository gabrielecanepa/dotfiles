#!/bin/zsh

function node-version() {
  case $1 in
    dump)
      echo ${$(node -v)#v} > ./.node-version
      ;;
    *)
      echo ${$(node -v)#v}
      ;;
  esac
}
