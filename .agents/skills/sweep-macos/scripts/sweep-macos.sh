#!/usr/bin/env bash
#
# sweep-macos - audit macOS for leftover data from uninstalled applications and stage reversible wipes.
#
# Usage:
#   sweep-macos.sh audit [--xdg] [--no-system] [--min-size-mb N] [--days N]
#   sweep-macos.sh apply --run DIR [--approved FILE]
#   sweep-macos.sh restore --run DIR [PATH...]
#
# audit is read-only. It builds the installed-software ground truth from bundles
# on disk (never LaunchServices), classifies leftovers into CONFIDENT, VERIFY,
# LIVE, CACHES, and REPORT buckets, and writes report.tsv, report.json,
# report.md, and the live-* set files into a dated run directory under the
# sweep-macos state directory. apply moves CONFIDENT rows plus explicitly approved
# paths to the user Trash (system paths into a sudo-staged directory inside the
# run) and records every move in manifest.tsv. restore replays the manifest in
# reverse. Nothing is ever rm'd.

set -euo pipefail

STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/sweep-macos"
DAYS=90
MIN_SIZE_MB=1
INCLUDE_XDG=0
INCLUDE_SYSTEM=1

RUN_DIR=""
WORK=""
ROWS=""
LIVE_IDS=""
LIVE_TEAMS=""
LIVE_NAMES=""
LIVE_VENDOR_TOKENS=""
GAPS=""
CUTOFF_REF=""
SKIP_COUNT_FILE=""

err() { printf 'sweep-macos: %s\n' "$*" >&2; }

die() {
  err "$*"
  exit 1
}

cleanup() {
  if [ -n "$WORK" ] && [ -d "$WORK" ]; then rm -rf "$WORK"; fi
}
trap cleanup EXIT

lower() { tr '[:upper:]' '[:lower:]'; }

normalize_name() { lower | tr -d ' _-'; }

regex_escape() { printf '%s' "$1" | sed 's/[][\.*^$]/\\&/g'; }

plist_read() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null || true
}

# Matching core. All live-set files hold lowercase entries; candidates are
# lowercased before lookup so matching is case-insensitive (APFS default).
id_match() {
  local id="$1" esc
  esc=$(regex_escape "$id")
  if grep -qxF -- "$id" "$LIVE_IDS"; then return 0; fi
  grep -q -- "^${esc}\." "$LIVE_IDS"
}

# Component count without awk: awk prints nothing on empty input, which turns
# the arithmetic tests below into syntax errors.
components() {
  local dots="${1//[^.]/}"
  printf '%s\n' "$((${#dots} + 1))"
}

# Strict ancestor matching: the id, each ancestor down to three components, and
# the direct parent when it still has three or more components. ${p%.*} avoids
# the awk trailing-dot bug on two-component ids.
strict_live() {
  local id p
  id=$(printf '%s' "$1" | lower)
  if [ -z "$id" ]; then return 1; fi
  if id_match "$id"; then return 0; fi
  p="$id"
  while [ "$(components "$p")" -gt 3 ]; do
    p="${p%.*}"
    if id_match "$p"; then return 0; fi
  done
  p="${id%.*}"
  if [ "$(components "$p")" -ge 3 ]; then
    if id_match "$p"; then return 0; fi
  fi
  return 1
}

# Vendor-level matching for Group Containers and Application Scripts, whose
# keys (TEAMID.com.vendor.app, group.com.vendor) do not map to bundle ids.
vendor_live() {
  local v
  v=$(printf '%s' "$1" | lower | awk -F. 'NF>=2 {print $1"."$2}')
  if [ -z "$v" ]; then return 1; fi
  id_match "$v"
}

team_live() { grep -qxF -- "$1" "$LIVE_TEAMS"; }

name_live() {
  local n
  n=$(printf '%s' "$1" | normalize_name)
  if [ -z "$n" ]; then return 1; fi
  if grep -qxF -- "$n" "$LIVE_NAMES"; then return 0; fi
  grep -qxF -- "$n" "$LIVE_VENDOR_TOKENS"
}

entry_size_kb() {
  local kb
  kb=$(du -sk -- "$1" 2>/dev/null | awk '{print $1; exit}') || true
  printf '%s\n' "${kb:-0}"
}

entry_is_warm() {
  [ -n "$(find "$1" -newer "$CUTOFF_REF" -print -quit 2>/dev/null)" ]
}

# Deep mtime: the newest file inside the tree, because a directory's own mtime
# does not change when nested files do. Shallow mode stats only the entry
# itself and is used for LIVE rows where a full scan buys nothing.
entry_mtime() {
  local mode="$1" path="$2" m=""
  if [ "$mode" = deep ]; then
    m=$(find "$path" -type f -exec stat -f %m {} + 2>/dev/null | sort -rn | head -n 1) || true
  fi
  if [ -z "$m" ]; then
    m=$(stat -f %m -- "$path" 2>/dev/null) || true
  fi
  if [ -z "$m" ]; then
    printf 'unknown\n'
    return
  fi
  date -r "$m" +%Y-%m-%d
}

emit_row() {
  # bucket category id path size_kb mtime reason
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7" >>"$ROWS"
}

count_skip() {
  printf '.' >>"$SKIP_COUNT_FILE"
}

add_gap() {
  printf '%s\n' "$1" >>"$GAPS"
}

# Ground truth for "installed": CFBundleIdentifier read off actual bundles on
# disk, nested helper bundles included, plus codesign team ids, launchd labels,
# running-app bundle ids, and receipts whose payload still exists. lsregister
# is never consulted; it holds stale records for deleted apps.
build_live_set() {
  local apps="$WORK/apps.txt" plist id name team app nested pkg vol loc base f found
  : >"$WORK/ids.raw"
  : >"$WORK/names.raw"
  : >"$WORK/teams.raw"
  : >"$WORK/dead-receipts.txt"

  {
    find /Applications "$HOME/Applications" -maxdepth 4 -name '*.app' -prune -print 2>/dev/null || true
    find /System/Applications -maxdepth 2 -name '*.app' -prune -print 2>/dev/null || true
  } >"$apps"

  while IFS= read -r app; do
    plist="$app/Contents/Info.plist"
    if [ ! -f "$plist" ]; then continue; fi
    id=$(plist_read "$plist" CFBundleIdentifier)
    if [ -n "$id" ]; then printf '%s\n' "$id" >>"$WORK/ids.raw"; fi
    basename "$app" .app >>"$WORK/names.raw"
    name=$(plist_read "$plist" CFBundleName)
    if [ -n "$name" ]; then printf '%s\n' "$name" >>"$WORK/names.raw"; fi
    case "$app" in
      /System/*) continue ;;
    esac
    team=$(codesign -dv --verbose=2 -- "$app" 2>&1 | awk -F= '/^TeamIdentifier=/ {print $2; exit}') || true
    if [ -n "$team" ] && [ "$team" != "not set" ]; then
      printf '%s\n' "$team" >>"$WORK/teams.raw"
    fi
    find "$app" -mindepth 1 -maxdepth 6 \( -name '*.app' -o -name '*.appex' -o -name '*.xpc' \) -print 2>/dev/null |
      while IFS= read -r nested; do
        id=$(plist_read "$nested/Contents/Info.plist" CFBundleIdentifier)
        if [ -n "$id" ]; then printf '%s\n' "$id" >>"$WORK/ids.raw"; fi
      done
  done <"$apps"

  # Runtime liveness: launchd labels (raw plus with per-launch numeric suffixes
  # stripped) and running-app bundle ids catch pkg-installed daemons and menu
  # bar apps that have no bundle under the application roots.
  launchctl list 2>/dev/null | awk 'NR>1 {print $3}' >"$WORK/launchd.raw" || true
  cat "$WORK/launchd.raw" >>"$WORK/ids.raw"
  sed -e 's/^application\.//' -e 's/\.[0-9][0-9]*\(\.[0-9][0-9]*\)*$//' "$WORK/launchd.raw" >>"$WORK/ids.raw"
  lsappinfo list 2>/dev/null | sed -n 's/.*bundleID="\([^"]*\)".*/\1/p' >>"$WORK/ids.raw" || true

  # A receipt alone is not liveness (uninstalled apps leave receipts). A
  # receipt whose payload still exists is ownership evidence for CLI-only
  # installs with no .app bundle.
  pkgutil --pkgs 2>/dev/null >"$WORK/pkgs.txt" || true
  while IFS= read -r pkg; do
    case "$pkg" in
      com.apple.*) continue ;;
    esac
    vol=$(pkgutil --pkg-info -- "$pkg" 2>/dev/null | awk -F': ' '/^volume: / {print $2; exit}') || true
    loc=$(pkgutil --pkg-info -- "$pkg" 2>/dev/null | awk -F': ' '/^location: / {print $2; exit}') || true
    base="${vol%/}/${loc#/}"
    base="${base%/}"
    found=0
    while IFS= read -r f; do
      if [ -e "$base/$f" ]; then
        found=1
        break
      fi
    done < <(pkgutil --files -- "$pkg" 2>/dev/null | head -n 12 || true)
    if [ "$found" = 1 ]; then
      printf '%s\n' "$pkg" >>"$WORK/ids.raw"
    else
      printf '%s\n' "$pkg" >>"$WORK/dead-receipts.txt"
    fi
  done <"$WORK/pkgs.txt"

  lower <"$WORK/ids.raw" | grep -v '^$' | sort -u >"$LIVE_IDS" || true
  sort -u "$WORK/teams.raw" >"$LIVE_TEAMS"
  normalize_name <"$WORK/names.raw" | grep -v '^$' | sort -u >"$LIVE_NAMES" || true
  awk -F. 'NF>=2 {print $2}' "$LIVE_IDS" | sort -u >"$LIVE_VENDOR_TOKENS"
}
display_path() {
  case "$1" in
    "$HOME"*) printf '~%s\n' "${1#"$HOME"}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

is_reverse_dns() {
  printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+){1,}$'
}

strip_suffixes() {
  local n="$1"
  n="${n%.lockfile}"
  n="${n%.plist}"
  n="${n%.savedState}"
  n="${n%.binarycookies}"
  n="${n%.xml}"
  printf '%s' "$n" | sed -E 's/\.[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$//'
}

# Human-named directories that belong to Apple system services but do not carry
# a com.apple prefix. Matching them by name against installed apps would flag
# live system data as orphaned.
write_skip_names() {
  cat >"$WORK/skip-names.txt" <<'EOF'
AddressBook
App Store
Apple
Autosave Information
ByHost
CallHistoryDB
CallHistoryTransactions
CloudDocs
CloudKit
CrashReporter
DiagnosticReports
DifferentialPrivacy
Dock
FaceTime
FileProvider
GameKit
GeoServices
iCloud
icdd
iLifeMediaBrowser
Knowledge
MobileSync
Sandbox
SyncServices
Ubiquity
EOF
}

live_row() {
  # family id path reason
  emit_row LIVE "$1" "$2" "$(display_path "$3")" "$(entry_size_kb "$3")" "$(entry_mtime shallow "$3")" "$4"
}

orphan_row() {
  local fam="$1" id="$2" path="$3" reason="$4" kb mt
  kb=$(entry_size_kb "$path")
  mt=$(entry_mtime deep "$path")
  if entry_is_warm "$path"; then
    emit_row VERIFY "$fam" "$id" "$(display_path "$path")" "$kb" "$mt" "$reason; touched within ${DAYS}d so a live helper may own it"
  else
    emit_row CONFIDENT "$fam" "$id" "$(display_path "$path")" "$kb" "$mt" "$reason; untouched for over ${DAYS}d"
  fi
}

classify_entry() {
  local rule="$1" path="$2" base cand bid team rest fam child
  base=$(basename "$path")
  fam=$(display_path "$(dirname "$path")")
  case "$base" in
    .DS_Store | .localized) return 0 ;;
  esac
  if grep -qxF -- "$path" "$WORK/cache-paths.txt" 2>/dev/null; then
    return 0
  fi
  if grep -qxF -- "$base" "$WORK/skip-names.txt"; then
    count_skip
    return 0
  fi
  # Shared generic containers such as Application Support/Caches hold one
  # subdirectory per tool (updater caches and the like); classify the
  # children, not the container.
  if [ "$base" = Caches ] && [ "$rule" = id ] && [ -d "$path" ]; then
    find "$path" -mindepth 1 -maxdepth 1 -print 2>/dev/null >"$WORK/generic-$$.txt" || true
    while IFS= read -r child; do
      classify_entry id "$child"
    done <"$WORK/generic-$$.txt"
    return 0
  fi
  bid=""
  if [ -f "$path/Contents/Info.plist" ]; then
    bid=$(plist_read "$path/Contents/Info.plist" CFBundleIdentifier)
  fi
  # macOS keeps some containers under UUID names; the true owner is in the
  # container metadata. A UUID whose metadata is unreadable is system-owned,
  # never an orphan candidate.
  if printf '%s' "$base" | grep -Eq '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'; then
    bid=$(plist_read "$path/.com.apple.containermanagerd.metadata.plist" MCMMetadataIdentifier)
    if [ -z "$bid" ]; then
      count_skip
      return 0
    fi
  fi
  cand=$(strip_suffixes "$base")
  if [ -n "$bid" ]; then cand="$bid"; fi
  case "$(printf '%s' "$cand" | lower)" in
    com.apple.* | systemgroup.* | is.workflow.* | group.com.apple.* | *.com.apple.*)
      count_skip
      return 0
      ;;
  esac
  if [ "$rule" = grp ]; then
    if printf '%s' "$cand" | grep -Eq '^[A-Z0-9]{10}\.'; then
      team="${cand%%.*}"
      rest="${cand#*.}"
      if team_live "$team"; then
        live_row "$fam" "$cand" "$path" "team id $team belongs to an installed app"
      elif vendor_live "$rest" || strict_live "$rest"; then
        live_row "$fam" "$cand" "$path" "vendor of $rest has an installed app"
      else
        orphan_row "$fam" "$cand" "$path" "team id and vendor match no installed app"
      fi
      return 0
    fi
    rest=$(printf '%s' "$cand" | sed -E 's/^groups?\.//')
    if vendor_live "$rest" || strict_live "$rest"; then
      live_row "$fam" "$cand" "$path" "vendor of $rest has an installed app"
    else
      orphan_row "$fam" "$cand" "$path" "vendor matches no installed app"
    fi
    return 0
  fi
  if is_reverse_dns "$cand"; then
    if strict_live "$cand"; then
      live_row "$fam" "$cand" "$path" "matches an installed bundle id"
    else
      orphan_row "$fam" "$cand" "$path" "matches no installed bundle id"
    fi
  else
    if name_live "$cand"; then
      live_row "$fam" "$cand" "$path" "name matches an installed app or vendor"
    else
      orphan_row "$fam" "$cand" "$path" "name matches no installed app or vendor"
    fi
  fi
}

scan_family_root() {
  local rule="$1" root="$2" entry
  if [ ! -d "$root" ]; then return 0; fi
  if ! ls "$root" >/dev/null 2>&1; then
    add_gap "no access (Full Disk Access?): $(display_path "$root")"
    return 0
  fi
  find "$root" -mindepth 1 -maxdepth 1 -print 2>/dev/null >"$WORK/family.txt" || true
  while IFS= read -r entry; do
    classify_entry "$rule" "$entry"
  done <"$WORK/family.txt"
}

# A launchd plist whose program binary is gone is orphaned regardless of id
# matching; one whose binary exists has an installed owner by definition.
scan_launchd_root() {
  local root="$1" plist label prog fam key
  if [ ! -d "$root" ]; then return 0; fi
  if ! ls "$root" >/dev/null 2>&1; then
    add_gap "no access: $(display_path "$root")"
    return 0
  fi
  fam=$(display_path "$root")
  find "$root" -mindepth 1 -maxdepth 1 -name '*.plist' -print 2>/dev/null >"$WORK/launchd-family.txt" || true
  while IFS= read -r plist; do
    label=$(plist_read "$plist" Label)
    key="$label"
    if [ -z "$key" ]; then key=$(strip_suffixes "$(basename "$plist")"); fi
    case "$(printf '%s' "$key" | lower)" in
      com.apple.*)
        count_skip
        continue
        ;;
    esac
    prog=$(plist_read "$plist" Program)
    if [ -z "$prog" ]; then prog=$(plist_read "$plist" 'ProgramArguments:0'); fi
    case "$prog" in
      /*)
        if [ -e "$prog" ]; then
          live_row "$fam" "$key" "$plist" "program exists: $prog"
        else
          emit_row CONFIDENT "$fam" "$key" "$(display_path "$plist")" "$(entry_size_kb "$plist")" \
            "$(entry_mtime shallow "$plist")" "program missing: $prog"
        fi
        ;;
      *)
        if strict_live "$key"; then
          live_row "$fam" "$key" "$plist" "label matches an installed bundle id"
        else
          orphan_row "$fam" "$key" "$plist" "label matches no installed bundle id"
        fi
        ;;
    esac
  done <"$WORK/launchd-family.txt"
}

# Native messaging host manifests point at a helper binary; a missing binary
# means the owning app is gone even when the browser is alive.
scan_nmh_root() {
  local root="$1" json target fam
  if [ ! -d "$root" ]; then return 0; fi
  fam=$(display_path "$root")
  find "$root" -mindepth 1 -maxdepth 1 -name '*.json' -print 2>/dev/null >"$WORK/nmh-family.txt" || true
  while IFS= read -r json; do
    target=$(sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$json" | head -n 1) || true
    if [ -n "$target" ] && [ ! -e "$target" ]; then
      emit_row CONFIDENT "$fam" "$(basename "$json" .json)" "$(display_path "$json")" \
        "$(entry_size_kb "$json")" "$(entry_mtime shallow "$json")" "host binary missing: $target"
    else
      live_row "$fam" "$(basename "$json" .json)" "$json" "host binary exists"
    fi
  done <"$WORK/nmh-family.txt"
}

# GarageBand, Logic, and their shared loops survive uninstalling the apps.
# Always VERIFY, never CONFIDENT: reinstalling restores the content, but it is
# a large download the user may prefer to keep.
scan_apple_stock() {
  local gb=0 lp=0 p
  if [ -d "/Applications/GarageBand.app" ]; then gb=1; fi
  if [ -d "/Applications/Logic Pro.app" ] || [ -d "/Applications/MainStage.app" ]; then lp=1; fi
  for p in "$HOME/Library/Application Support/GarageBand" "/Library/Application Support/GarageBand"; do
    if [ ! -e "$p" ]; then continue; fi
    if [ "$gb" = 1 ] || [ "$lp" = 1 ]; then
      live_row "apple stock" GarageBand "$p" "GarageBand or Logic is installed"
    else
      emit_row VERIFY "apple stock" GarageBand "$(display_path "$p")" "$(entry_size_kb "$p")" \
        "$(entry_mtime shallow "$p")" "stock content for uninstalled GarageBand; reinstall restores it"
    fi
  done
  for p in "/Library/Application Support/Logic" "$HOME/Library/Application Support/Logic"; do
    if [ ! -e "$p" ]; then continue; fi
    if [ "$lp" = 1 ]; then
      live_row "apple stock" Logic "$p" "Logic or MainStage is installed"
    else
      emit_row VERIFY "apple stock" Logic "$(display_path "$p")" "$(entry_size_kb "$p")" \
        "$(entry_mtime shallow "$p")" "stock content for uninstalled Logic; reinstall restores it"
    fi
  done
  for p in "/Library/Audio/Apple Loops" "/Library/Audio/Apple Loops Index"; do
    if [ ! -e "$p" ]; then continue; fi
    if [ "$gb" = 1 ] || [ "$lp" = 1 ]; then
      live_row "apple stock" "Apple Loops" "$p" "GarageBand or Logic is installed"
    else
      emit_row VERIFY "apple stock" "Apple Loops" "$(display_path "$p")" "$(entry_size_kb "$p")" \
        "$(entry_mtime shallow "$p")" "loops for uninstalled GarageBand and Logic; reinstall restores them"
    fi
  done
}
# REPORT rows are informational forever: receipts are the only trace of what a
# pkg placed on disk, and deleting an iCloud container removes data from every
# device, not just this machine.
scan_report_only() {
  local root="$HOME/Library/Mobile Documents" entry id pkg line target p
  if [ -d "$root" ]; then
    if ls "$root" >/dev/null 2>&1; then
      find "$root" -mindepth 1 -maxdepth 1 -name 'iCloud~*' -print 2>/dev/null >"$WORK/icloud.txt" || true
      while IFS= read -r entry; do
        id=$(basename "$entry" | sed -e 's/^iCloud~//' -e 's/~/./g')
        if strict_live "$id"; then
          live_row "iCloud containers" "$id" "$entry" "matches an installed bundle id"
        else
          emit_row REPORT "iCloud containers" "$id" "$(display_path "$entry")" "$(entry_size_kb "$entry")" \
            "$(entry_mtime shallow "$entry")" "orphaned iCloud container; deleting would remove iCloud data on every device"
        fi
      done <"$WORK/icloud.txt"
    else
      add_gap "no access (Full Disk Access?): $(display_path "$root")"
    fi
  fi

  while IFS= read -r pkg; do
    emit_row REPORT receipts "$pkg" "/var/db/receipts/$pkg" 0 unknown \
      "receipt for an absent payload; keep as the install manifest (pkgutil --files)"
  done <"$WORK/dead-receipts.txt"

  systemextensionsctl list 2>/dev/null |
    awk '{for (i = 1; i <= NF; i++) if ($i ~ /^[A-Za-z0-9-]+(\.[A-Za-z0-9_-]+){2,}$/) print $i}' |
    sort -u >"$WORK/sysext.txt" || true
  while IFS= read -r id; do
    case "$id" in
      com.apple.*) continue ;;
    esac
    if ! strict_live "$id"; then
      emit_row REPORT "system extensions" "$id" systemextensionsctl 0 unknown \
        "extension registered for a missing app; removal needs systemextensionsctl uninstall"
    fi
  done <"$WORK/sysext.txt"

  if [ -d /usr/local ]; then
    find /usr/local -mindepth 1 -maxdepth 1 -print 2>/dev/null >"$WORK/usrlocal.txt" || true
    while IFS= read -r entry; do
      emit_row REPORT /usr/local "$(basename "$entry")" "$entry" "$(entry_size_kb "$entry")" \
        "$(entry_mtime shallow "$entry")" "outside the Homebrew prefix; likely pkg leftover, trace with pkgutil"
    done <"$WORK/usrlocal.txt"
  fi

  for p in /etc/paths.d /etc/manpaths.d; do
    if [ ! -d "$p" ]; then continue; fi
    find "$p" -type f -print 2>/dev/null >"$WORK/pathsd.txt" || true
    while IFS= read -r entry; do
      grep '^/' "$entry" 2>/dev/null >"$WORK/paths-lines.txt" || true
      while IFS= read -r line; do
        if [ ! -d "$line" ]; then
          emit_row REPORT "$p" "$(basename "$entry")" "$entry" 0 \
            "$(entry_mtime shallow "$entry")" "PATH entry points at missing directory $line"
        fi
      done <"$WORK/paths-lines.txt"
    done <"$WORK/pathsd.txt"
  done

  sfltool dumpbtm 2>/dev/null | sed -n 's/^[[:space:]]*Executable Path:[[:space:]]*//p' |
    sort -u >"$WORK/btm.txt" || true
  if [ -s "$WORK/btm.txt" ]; then
    while IFS= read -r target; do
      case "$target" in
        /*)
          if [ ! -e "$target" ]; then
            emit_row REPORT "background items" "$(basename "$target")" "$target" 0 unknown \
              "login or background item points at a missing executable (sfltool dumpbtm)"
          fi
          ;;
      esac
    done <"$WORK/btm.txt"
  else
    add_gap "login and background items not checked: sfltool dumpbtm needs sudo"
  fi
}

# Regenerable caches of live tools. They are excluded from orphan logic on
# purpose: the owner is installed, the data is just re-creatable. Only listed
# above 100 MB so the bucket stays signal.
cache_list() {
  cat <<'EOF'
~/Library/Developer/Xcode/DerivedData|Xcode rebuilds on the next build
~/Library/Developer/Xcode/iOS DeviceSupport|recreated on the next device connect
~/Library/Developer/Xcode/watchOS DeviceSupport|recreated on the next device connect
~/Library/Developer/CoreSimulator/Caches|recreated by the simulator
~/Library/Developer/CoreSimulator/Devices|prune stale runtimes with xcrun simctl delete unavailable
~/Library/Caches/ms-playwright|reinstall with pnpm exec playwright install
~/Library/Caches/Homebrew|prune with brew cleanup --prune=all
~/Library/Caches/pip|pip re-downloads on demand
~/Library/Caches/Google|the browser rebuilds its cache
~/Library/Caches/com.apple.Safari|the browser rebuilds its cache
~/Library/Caches/Mozilla|the browser rebuilds its cache
~/Library/pnpm/store|prune with pnpm store prune
~/.npm/_cacache|prune with npm cache clean --force
~/.cache/huggingface|models re-download on demand
~/.ollama/models|models re-download with ollama pull
EOF
}

# The family scanners consult this so a curated cache is never also classified
# as an orphan candidate; it belongs to CACHES alone.
write_cache_paths() {
  cache_list | while IFS='|' read -r p _; do
    printf '%s\n' "$HOME${p#\~}"
  done >"$WORK/cache-paths.txt"
}

scan_caches() {
  local path note kb
  while IFS='|' read -r path note; do
    if [ -z "$path" ]; then continue; fi
    case "$path" in
      "~"*) path="$HOME${path#\~}" ;;
    esac
    if [ ! -e "$path" ]; then continue; fi
    kb=$(entry_size_kb "$path")
    if [ "$kb" -lt 102400 ]; then continue; fi
    emit_row CACHES "regenerable caches" "$(basename "$path")" "$(display_path "$path")" "$kb" \
      "$(entry_mtime shallow "$path")" "regenerable: $note"
  done < <(cache_list)
}

# XDG and dotfile directories have no bundle ids, so ownership is heuristic:
# a matching command, Homebrew formula or cask, or app name counts as an owner.
# Nothing here is ever CONFIDENT; unowned entries land in VERIFY and are only
# wiped through explicit approval.
scan_xdg() {
  local root entry name
  brew list --formula 2>/dev/null >"$WORK/brew.txt" || true
  brew list --cask 2>/dev/null >>"$WORK/brew.txt" || true
  for root in "$HOME/.cache" "$HOME/.config" "$HOME/.local/share" "$HOME/.local/state" "$HOME"; do
    if [ ! -d "$root" ]; then continue; fi
    if [ "$root" = "$HOME" ]; then
      find "$root" -mindepth 1 -maxdepth 1 -type d -name '.*' -print 2>/dev/null >"$WORK/xdg.txt" || true
    else
      find "$root" -mindepth 1 -maxdepth 1 -print 2>/dev/null >"$WORK/xdg.txt" || true
    fi
    while IFS= read -r entry; do
      name=$(basename "$entry")
      case "$name" in
        .DS_Store | .Trash | .git | .cache | .config | .local) continue ;;
      esac
      # Tracked in the dotfiles repository means managed configuration, not a
      # leftover.
      if git -C "$HOME" ls-files --error-unmatch -- "$entry" >/dev/null 2>&1; then
        continue
      fi
      name="${name#.}"
      if command -v -- "$name" >/dev/null 2>&1 || grep -qixF -- "$name" "$WORK/brew.txt" || name_live "$name"; then
        live_row xdg "$name" "$entry" "matching command, formula, or app is installed"
      else
        emit_row VERIFY xdg "$name" "$(display_path "$entry")" "$(entry_size_kb "$entry")" \
          "$(entry_mtime deep "$entry")" "no matching command or app; dotdir ownership is heuristic"
      fi
    done <"$WORK/xdg.txt"
  done
}

human_size() {
  awk -v kb="$1" 'BEGIN {
    if (kb >= 1048576) printf "%.2f GB", kb / 1048576
    else if (kb >= 1024) printf "%.1f MB", kb / 1024
    else printf "%d KB", kb
  }'
}

bucket_total_kb() {
  awk -F'\t' -v b="$1" '$1 == b {s += $5} END {print s + 0}' "$ROWS"
}

write_bucket_section() {
  local bucket="$1" title="$2" out="$3" min_kb small_kb small_n
  min_kb=$((MIN_SIZE_MB * 1024))
  {
    printf '## %s\n\n' "$title"
    printf 'Total: %s\n\n' "$(human_size "$(bucket_total_kb "$bucket")")"
    if ! awk -F'\t' -v b="$bucket" '$1 == b' "$ROWS" | grep -q .; then
      printf 'Nothing found.\n\n'
      return 0
    fi
    printf '| Path | Id | Size | Newest mtime | Why |\n'
    printf '| --- | --- | --- | --- | --- |\n'
    awk -F'\t' -v b="$bucket" -v min="$min_kb" '$1 == b && $5 >= min' "$ROWS" |
      sort -t "$(printf '\t')" -k5,5rn |
      while IFS=$'\t' read -r _ _ id path kb mt reason; do
        printf '| %s | %s | %s | %s | %s |\n' "$path" "$id" "$(human_size "$kb")" "$mt" "$reason"
      done
    small_kb=$(awk -F'\t' -v b="$bucket" -v min="$min_kb" '$1 == b && $5 < min {s += $5} END {print s + 0}' "$ROWS")
    small_n=$(awk -F'\t' -v b="$bucket" -v min="$min_kb" '$1 == b && $5 < min {n++} END {print n + 0}' "$ROWS")
    if [ "$small_n" -gt 0 ]; then
      printf '\n%s smaller items totalling %s are listed only in report.tsv.\n' "$small_n" "$(human_size "$small_kb")"
    fi
    printf '\n'
  } >>"$out"
}

write_report_md() {
  local out="$RUN_DIR/report.md" gap
  {
    printf '# sweep-macos audit %s\n\n' "$(date +%Y-%m-%d)"
    printf 'Cutoff: %s days (deep mtime). Live set: %s bundle ids, %s team ids, %s names. ' \
      "$DAYS" "$(wc -l <"$LIVE_IDS" | tr -d ' ')" "$(wc -l <"$LIVE_TEAMS" | tr -d ' ')" \
      "$(wc -l <"$LIVE_NAMES" | tr -d ' ')"
    printf 'Apple and system entries skipped: %s.\n\n' "$(wc -c <"$SKIP_COUNT_FILE" | tr -d ' ')"
    if [ -s "$GAPS" ]; then
      printf '## Gaps\n\n'
      while IFS= read -r gap; do printf -- '- %s\n' "$gap"; done <"$GAPS"
      printf '\n'
    fi
  } >"$out"
  write_bucket_section CONFIDENT 'CONFIDENT: no owner, cold' "$out"
  write_bucket_section VERIFY 'VERIFY: ambiguous, needs human eyes' "$out"
  write_bucket_section CACHES 'CACHES: regenerable, owner is live' "$out"
  write_bucket_section REPORT 'REPORT: informational, never wiped' "$out"
  write_bucket_section LIVE 'LIVE: excluded, audit the exclusions' "$out"
  {
    printf '## Notes\n\n'
    printf -- '- Wipes move data to the Trash or a staged directory; nothing is ever rm'"'"'d.\n'
    printf -- '- Freed space appears once local Time Machine snapshots thin out.\n'
    printf -- '- Apply: sweep-macos.sh apply --run %s [--approved FILE]\n' "$RUN_DIR"
  } >>"$out"
}

je() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

write_report_json() {
  local out="$RUN_DIR/report.json" first=1 bucket fam id path kb mt reason
  {
    printf '[\n'
    while IFS=$'\t' read -r bucket fam id path kb mt reason; do
      if [ "$first" = 1 ]; then first=0; else printf ',\n'; fi
      printf '  {"bucket":"%s","family":"%s","id":"%s","path":"%s","size_kb":%s,"mtime":"%s","reason":"%s"}' \
        "$(je "$bucket")" "$(je "$fam")" "$(je "$id")" "$(je "$path")" "${kb:-0}" "$(je "$mt")" "$(je "$reason")"
    done <"$ROWS"
    printf '\n]\n'
  } >"$out"
}

scan_user_families() {
  local rule root
  while IFS='|' read -r rule root; do
    if [ -z "$rule" ]; then continue; fi
    root="$HOME${root#\~}"
    case "$rule" in
      id | grp) scan_family_root "$rule" "$root" ;;
      launchd) scan_launchd_root "$root" ;;
      nmh) scan_nmh_root "$root" ;;
    esac
  done <<'EOF'
id|~/Library/Application Support
id|~/Library/Caches
id|~/Library/Containers
grp|~/Library/Group Containers
grp|~/Library/Application Scripts
id|~/Library/Preferences
id|~/Library/Preferences/ByHost
id|~/Library/HTTPStorages
id|~/Library/WebKit
id|~/Library/Saved Application State
id|~/Library/Logs
id|~/Library/Cookies
id|~/Library/SyncedPreferences
id|~/Library/Internet Plug-Ins
id|~/Library/Services
id|~/Library/PreferencePanes
id|~/Library/Screen Savers
id|~/Library/QuickLook
id|~/Library/Spotlight
id|~/Library/Widgets
id|~/Library/Audio/Plug-Ins
id|~/Library/Input Methods
id|~/Library/Automator
id|~/Library/ColorPickers
id|~/Library/Keyboard Layouts
id|~/Library/PDF Services
id|~/Library/Contextual Menu Items
id|~/Library/Address Book Plug-Ins
id|~/Library/Mail/Bundles
launchd|~/Library/LaunchAgents
nmh|~/Library/Application Support/Google/Chrome/NativeMessagingHosts
nmh|~/Library/Application Support/Microsoft Edge/NativeMessagingHosts
nmh|~/Library/Application Support/Mozilla/NativeMessagingHosts
EOF
}

scan_system_families() {
  local rule root
  while IFS='|' read -r rule root; do
    if [ -z "$rule" ]; then continue; fi
    case "$rule" in
      id | grp) scan_family_root "$rule" "$root" ;;
      launchd) scan_launchd_root "$root" ;;
      nmh) scan_nmh_root "$root" ;;
    esac
  done <<'EOF'
id|/Library/Application Support
id|/Library/Preferences
id|/Library/Caches
id|/Library/PrivilegedHelperTools
id|/Library/Extensions
id|/Library/Internet Plug-Ins
id|/Library/PreferencePanes
id|/Library/QuickLook
id|/Library/Audio/Plug-Ins
id|/Library/Input Methods
id|/Library/Frameworks
id|/Library/ScriptingAdditions
id|/Library/Printers
id|/Library/Documentation
id|/Library/Logs
id|/Library/Keyboard Layouts
id|/Library/Java/JavaVirtualMachines
id|/Library/Python
id|/Library/Ruby
id|/Users/Shared
launchd|/Library/LaunchAgents
launchd|/Library/LaunchDaemons
nmh|/Library/Google/Chrome/NativeMessagingHosts
nmh|/Library/Application Support/Mozilla/NativeMessagingHosts
nmh|/Library/Microsoft/Edge/NativeMessagingHosts
EOF
}

cmd_audit() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --xdg) INCLUDE_XDG=1 ;;
      --no-system) INCLUDE_SYSTEM=0 ;;
      --min-size-mb)
        shift
        MIN_SIZE_MB="${1:?--min-size-mb needs a value}"
        ;;
      --days)
        shift
        DAYS="${1:?--days needs a value}"
        ;;
      *) die "unknown audit option: $1" ;;
    esac
    shift
  done
  RUN_DIR="$STATE_ROOT/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$RUN_DIR"
  WORK=$(mktemp -d)
  ROWS="$RUN_DIR/report.tsv"
  LIVE_IDS="$RUN_DIR/live-ids.txt"
  LIVE_TEAMS="$RUN_DIR/live-teams.txt"
  LIVE_NAMES="$RUN_DIR/live-names.txt"
  LIVE_VENDOR_TOKENS="$RUN_DIR/live-vendor-tokens.txt"
  GAPS="$WORK/gaps.txt"
  SKIP_COUNT_FILE="$WORK/skips"
  : >"$ROWS"
  : >"$GAPS"
  : >"$SKIP_COUNT_FILE"
  CUTOFF_REF="$WORK/cutoff"
  touch -t "$(date -v "-${DAYS}d" +%Y%m%d%H%M)" "$CUTOFF_REF"
  err "building the installed-software ground truth (bundles, launchd, receipts)"
  build_live_set
  write_skip_names
  write_cache_paths
  err "scanning user library families"
  scan_user_families
  if [ "$INCLUDE_SYSTEM" = 1 ]; then
    err "scanning system library families"
    scan_system_families
  fi
  scan_apple_stock
  scan_report_only
  scan_caches
  if [ "$INCLUDE_XDG" = 1 ]; then
    err "scanning XDG and dotfile directories"
    scan_xdg
  fi
  write_report_md
  write_report_json
  err "audit written to $RUN_DIR"
  printf '%s\n' "$RUN_DIR"
}
expand_path() {
  case "$1" in
    "~"*) printf '%s\n' "$HOME${1#\~}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# Refuse anything that is not a plain absolute path inside the scanned roots.
# The wipe path must stay incapable of touching a home directory, a library
# root, or an arbitrary path smuggled into an approved file.
safe_target() {
  local p="$1"
  case "$p" in
    /*) ;;
    *) return 1 ;;
  esac
  case "$p" in
    / | /Library | /Users | /Users/Shared | "$HOME" | "$HOME/Library") return 1 ;;
  esac
  case "$p" in
    "$HOME"/* | /Library/* | /Users/Shared/*) return 0 ;;
  esac
  return 1
}

cmd_apply() {
  local run="" approved="" manifest trash_dir staged idx moved_kb=0 moved_n=0
  local bucket fam id disp kb mt reason abs sel dest
  while [ $# -gt 0 ]; do
    case "$1" in
      --run)
        shift
        run="${1:?--run needs a directory}"
        ;;
      --approved)
        shift
        approved="${1:?--approved needs a file}"
        ;;
      *) die "unknown apply option: $1" ;;
    esac
    shift
  done
  if [ -z "$run" ]; then die "apply needs --run DIR (an audit run directory)"; fi
  ROWS="$run/report.tsv"
  if [ ! -f "$ROWS" ]; then die "no report.tsv in $run; run an audit first"; fi
  if [ -n "$approved" ] && [ ! -f "$approved" ]; then die "approved file not found: $approved"; fi
  if [ "$(id -u)" = 0 ]; then die "run apply as your user; sudo is invoked per move for system paths"; fi
  manifest="$run/manifest.tsv"
  trash_dir="$HOME/.Trash/sweep-macos-$(basename "$run")"
  staged="$run/staged-system"
  idx=0
  if [ -f "$manifest" ]; then idx=$(wc -l <"$manifest" | tr -d ' '); fi
  while IFS=$'\t' read -r bucket fam id disp kb mt reason; do
    sel=0
    abs=$(expand_path "$disp")
    if [ "$bucket" = CONFIDENT ]; then
      sel=1
    elif [ -n "$approved" ] && { [ "$bucket" = VERIFY ] || [ "$bucket" = CACHES ]; }; then
      if grep -qxF -- "$disp" "$approved" || grep -qxF -- "$abs" "$approved"; then sel=1; fi
    fi
    if [ "$sel" = 0 ]; then continue; fi
    if [ ! -e "$abs" ]; then
      err "skip (already gone): $disp"
      continue
    fi
    if ! safe_target "$abs"; then
      err "skip (outside the allowed roots): $disp"
      continue
    fi
    idx=$((idx + 1))
    case "$abs" in
      "$HOME"/*)
        mkdir -p "$trash_dir"
        dest=$(printf '%s/%03d-%s' "$trash_dir" "$idx" "$(basename "$abs")")
        mv -- "$abs" "$dest"
        ;;
      *)
        mkdir -p "$staged"
        dest=$(printf '%s/%03d-%s' "$staged" "$idx" "$(basename "$abs")")
        sudo mv -- "$abs" "$dest"
        ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\n' "$idx" "$bucket" "$abs" "$dest" "$kb" >>"$manifest"
    moved_kb=$((moved_kb + kb))
    moved_n=$((moved_n + 1))
    err "moved: $disp -> $dest"
  done <"$ROWS"
  err "done: $moved_n items, $(human_size "$moved_kb") staged"
  err "manifest: $manifest"
  err "undo with: sweep-macos.sh restore --run $run"
  printf '%s\n' "$manifest"
}

cmd_restore() {
  local run="" idx bucket orig dest kb match p restored=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --run)
        shift
        run="${1:?--run needs a directory}"
        break
        ;;
      *) die "unknown restore option: $1" ;;
    esac
  done
  shift || true
  if [ -z "$run" ]; then die "restore needs --run DIR"; fi
  if [ ! -f "$run/manifest.tsv" ]; then die "no manifest.tsv in $run; nothing to restore"; fi
  while IFS=$'\t' read -r idx bucket orig dest kb; do
    if [ $# -gt 0 ]; then
      match=0
      for p in "$@"; do
        if [ "$(expand_path "$p")" = "$orig" ]; then match=1; fi
      done
      if [ "$match" = 0 ]; then continue; fi
    fi
    if [ ! -e "$dest" ]; then
      err "skip (staged copy gone): $dest"
      continue
    fi
    if [ -e "$orig" ]; then
      err "skip (original path exists again): $orig"
      continue
    fi
    case "$orig" in
      "$HOME"/*)
        mkdir -p "$(dirname "$orig")"
        mv -- "$dest" "$orig"
        ;;
      *)
        sudo mkdir -p "$(dirname "$orig")"
        sudo mv -- "$dest" "$orig"
        ;;
    esac
    restored=$((restored + 1))
    err "restored: $orig"
  done <"$run/manifest.tsv"
  err "done: $restored items restored"
}

usage() {
  cat <<'EOF'
sweep-macos - audit macOS for leftover data from uninstalled applications.

Usage:
  sweep-macos.sh audit [--xdg] [--no-system] [--min-size-mb N] [--days N]
  sweep-macos.sh apply --run DIR [--approved FILE]
  sweep-macos.sh restore --run DIR [PATH...]

audit    Read-only scan. Prints the run directory on stdout; writes report.md,
         report.tsv, report.json, and the live-* set files there.
apply    Move CONFIDENT rows, plus VERIFY or CACHES paths listed in the
         approved file, to the Trash (system paths to a sudo staging directory
         inside the run). Records every move in manifest.tsv.
restore  Move staged items back to their original paths, all or only the PATHs
         given.
EOF
}

main() {
  if [ "$(uname)" != Darwin ]; then die "macOS only"; fi
  case "${1:-}" in
    audit | apply | restore)
      local cmd="$1"
      shift
      "cmd_$cmd" "$@"
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
