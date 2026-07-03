npm_global_install_saved() {
  [ "$STATUS" = "0" ] || return 0
  local deps
  deps="$("$PREFIX/bin/node" -p 'const d=require(process.argv[1]).dependencies||{};Object.entries(d).map(([k,v])=>k+"@"+v).join(" ")' "${NPM_GLOBAL:-$HOME/.npm}/package.json" 2>/dev/null)" || return 0
  [ -n "$deps" ] || return 0
  local -a packages
  read -r -a packages <<<"$deps" || return 0
  PATH="$PREFIX/bin:$PATH" "$PREFIX/bin/npm" install --global "${packages[@]}" >/dev/null 2>&1 || true
}

after_install npm_global_install_saved
