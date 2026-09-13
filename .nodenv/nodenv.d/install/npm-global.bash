npm_global_install() {
  [ "$STATUS" = "0" ] || return 0
  local deps
  deps="$("$PREFIX/bin/node" -p 'const d=require(process.argv[1]).dependencies||{};Object.entries(d).map(([k,v])=>k+"@"+v).join("\n")' "${NPM_GLOBAL:-$HOME/.npm}/package.json" 2>/dev/null)" || return 0
  [ -n "$deps" ] || return 0
  local -a packages=()
  local package
  while IFS= read -r package; do
    [ -n "$package" ] || continue
    packages+=("$package")
  done <<<"$deps"
  PATH="$PREFIX/bin:$PATH" "$PREFIX/bin/npm" install --global "${packages[@]}" >/dev/null 2>&1 || true
}

after_install npm_global_install
