tab() {
  osascript -i >/dev/null 2>&1 <<EOF
    tell application "iTerm2"
      tell current window
        create tab with default profile
      end tell
    end tell
EOF
}
