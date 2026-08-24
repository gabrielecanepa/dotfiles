corepack_enable() {
  [ "$STATUS" = "0" ] || return 0
  [ -x "$PREFIX/bin/corepack" ] || return 0
  "$PREFIX/bin/corepack" enable --install-directory "$PREFIX/bin" >/dev/null 2>&1 || true
}

after_install corepack_enable
