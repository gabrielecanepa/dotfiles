#!/usr/bin/env bash
#
# Close every agent-browser session and reap daemons leaked by earlier sessions.
# Run manually only when no other browser work is active: the daemon detaches to
# parent 1 even while healthy, so the reap cannot tell a leak from a live session
# owned by another agent. A dead session leaves an orphaned daemon holding
# roughly 900 MB of Chrome processes that close --all can no longer reach, so
# that process is killed directly. nodenv installs the CLI per Node version and a version link
# can dangle into a removed project or worktree, so a working binary is probed
# newest-first. A watchdog bounds the close call. Fails open: a missing CLI or
# state directory skips that step. macOS.

set -uo pipefail

resolve_cli() {
  if command -v agent-browser >/dev/null 2>&1 && agent-browser --version >/dev/null 2>&1; then
    command -v agent-browser
    return 0
  fi
  local candidate
  while read -r candidate; do
    if [[ -x $candidate ]] && "$candidate" --version >/dev/null 2>&1; then
      printf '%s' "$candidate"
      return 0
    fi
  done < <(find "${NODENV_ROOT:-$HOME/.nodenv}/versions" -maxdepth 3 -name agent-browser 2>/dev/null | sort -Vr)
}

cli=$(resolve_cli)
if [[ -n $cli ]]; then
  "$cli" close --all >/dev/null 2>&1 &
  close=$!
  (sleep 10 && kill -9 "$close" 2>/dev/null) >/dev/null 2>&1 &
  watchdog=$!
  disown "$watchdog"
  wait "$close" 2>/dev/null
  kill "$watchdog" 2>/dev/null
fi

orphans=$(pgrep -f 'node_modules/agent-browser|\.agent-browser/browsers' 2>/dev/null |
  while read -r pid; do
    [[ $(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ') == 1 ]] && printf '%s\n' "$pid"
  done)

if [[ -n $orphans ]]; then
  # shellcheck disable=SC2086
  kill $orphans 2>/dev/null
  sleep 2
  # shellcheck disable=SC2086
  kill -9 $orphans 2>/dev/null
fi

state="$HOME/.agent-browser"
if [[ -d $state ]]; then
  find "$state/sessions" -maxdepth 1 -name '*.json' -mtime +3 -delete 2>/dev/null
  find "$state" -maxdepth 1 \( -name '*.config' -o -name '*.log' \) -mtime +3 -delete 2>/dev/null
fi

exit 0
