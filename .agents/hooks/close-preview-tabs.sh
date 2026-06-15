#!/usr/bin/env bash

# Stop + SessionEnd hook: close browser tabs left open by Claude's preview/test
# runs. Stop fires on normal task completion (prompt cleanup); SessionEnd is the
# backstop for tasks ended by interrupt (no hook fires on Esc/Ctrl+C).
# Matches localhost preview URLs (the Claude in Chrome extension never tears down
# its own tab groups, and Chrome's AppleScript dictionary doesn't expose tab
# groups, so we target by URL instead). macOS only; no-op elsewhere.
# Set CLOSE_PREVIEW_TABS_DEBUG=1 to trace per-browser outcomes on stderr.

[ "$(uname)" = "Darwin" ] || exit 0

log() { [ -n "$CLOSE_PREVIEW_TABS_DEBUG" ] && printf 'close-preview-tabs: %s\n' "$1" >&2; }

close_in() {
  app="$1"
  osascript <<APPLESCRIPT
if application "$app" is not running then return
tell application "$app"
  repeat with w in windows
    set i to (count of tabs of w)
    repeat while i > 0
      set u to URL of tab i of w
      if (u contains "localhost") or (u contains "127.0.0.1") then
        close tab i of w
      end if
      set i to i - 1
    end repeat
  end repeat
end tell
APPLESCRIPT
}

for app in "Google Chrome" "Microsoft Edge" "Arc" "Brave Browser"; do
  if close_in "$app" 2>/dev/null; then
    log "processed $app"
  else
    log "skipped $app (not installed/running or AppleScript error)"
  fi
done

exit 0
