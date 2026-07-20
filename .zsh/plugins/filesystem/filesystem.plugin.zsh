#
# filesystem: utilities and wrappers to list files, see directory sizes, print PATH/FPATH, and recursively remove directories.
# Usage: ls | ll | lss [<dir>...] | path | fpath | rmm <name>... | mkdircd <dir> | mkdircode <dir>
#

if (( $+commands[gls] )); then
  # Ignore macOS Icon files and Finder metadata.
  alias ls="gls -Hh --color --group-directories-first -I 'Icon'$'\r' -I .DS_Store -I .localized"
else
  alias ls="/bin/ls -GHhp"
fi

alias ll="ls -la"

lss() {
  emulate -L zsh
  local -a du_cmd
  if (( $+commands[gdu] )); then
    du_cmd=(command gdu -L --si -d 1)
  else
    du_cmd=(command du -L -h -d 1)
  fi
  "${du_cmd[@]}" "$@" 2>/dev/null | command sort -hr
}

path() {
  emulate -L zsh
  # (s/:/) splits the value on ":" into one element per directory
  print -rl -- "${(s/:/)PATH}"
}

fpath() {
  emulate -L zsh
  print -rl -- "${(s/:/)FPATH}"
}

rmm() {
  emulate -L zsh
  local folder
  for folder in "$@"; do
    # -prune stops find from descending into the match before rm removes it.
    command find . -type d -name "$folder" -prune -exec rm -rf {} +
  done
}

mkdircd() {
  emulate -L zsh
  mkdir -pv "$1" && cd "$1"
}

mkdircode() {
  emulate -L zsh
  mkdir -pv "$1" && command code "$1"
}
