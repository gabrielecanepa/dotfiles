# Print the 256 xterm color codes, each on a swatch of its own color, 16 per row.
#
# Usage: colors256

colors256() {
  emulate -L zsh

  local code

  for code in {000..255}; do
    print -nP -- "%F{$code}$code %f"
    (( code % 16 == 15 )) && print
  done
}
