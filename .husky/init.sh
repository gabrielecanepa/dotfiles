#!/bin/sh

export HUSKY="$HOME/.husky"

run() {
  . "${HUSKY}/plugins/${1}.sh"
}
