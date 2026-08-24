colors256() {
  emulate -L zsh

  local code

  for code in {000..255}; do
    print -nP -- "%F{$code}$code %f"
    (( code % 16 == 15 )) && print
  done
}
