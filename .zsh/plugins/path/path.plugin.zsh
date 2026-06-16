# Print PATH and FPATH entries one per line.
#
# Usage: path
#        fpath

path() {
  emulate -L zsh
  # (s/:/) splits the value on ":" into one element per directory
  print -rl -- "${(s/:/)PATH}"
}

fpath() {
  emulate -L zsh
  print -rl -- "${(s/:/)FPATH}"
}
