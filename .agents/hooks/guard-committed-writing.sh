#!/bin/sh
#
# PreToolUse guardrail (Edit|Write|MultiEdit): enforce the AGENTS.md
# committed-writing and portability hard boundaries at write time. Blocks a
# tool call that ADDS an em or en dash, or a machine-specific /Users/<name>
# path, to a file inside a git work tree that is not gitignored (the
# "committed file" scope; scratch and generated paths are ignored, so they
# pass). Pre-existing occurrences are allowed: only a net increase over the
# replaced text (Edit/MultiEdit) or the current file content (Write) blocks.
# Exit 2 blocks; missing jq/git or any probe failure fails open (exit 0).

set -u

case ":$PATH:" in
  *:/opt/homebrew/bin:*) ;;
  *) PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" ;;
esac

input="$(cat)"
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
[ -n "$fp" ] || exit 0

case "$fp" in
  /*) abs="$fp" ;;
  *) abs="$PWD/$fp" ;;
esac

dir="$(dirname "$abs")"
while [ ! -d "$dir" ] && [ "$dir" != "/" ]; do dir="$(dirname "$dir")"; done
git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
git -C "$dir" check-ignore -q "$abs" 2>/dev/null && exit 0

content="$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.file_text // empty' 2>/dev/null)"
if [ -n "$content" ]; then
  new="$content"
  old="$(cat "$abs" 2>/dev/null || true)"
else
  new="$(printf '%s' "$input" | jq -r '(.tool_input.new_string // .tool_input.new_str // empty), ((.tool_input.edits // [])[].new_string // empty)' 2>/dev/null)"
  old="$(printf '%s' "$input" | jq -r '(.tool_input.old_string // .tool_input.old_str // empty), ((.tool_input.edits // [])[].old_string // empty)' 2>/dev/null)"
fi
[ -n "$new" ] || exit 0

deny() {
  printf 'Blocked by guard-committed-writing: %s\n' "$1" >&2
  exit 2
}

em="$(printf '\342\200\224')"
en="$(printf '\342\200\223')"

count_dashes() { printf '%s' "$1" | grep -o -F -e "$em" -e "$en" 2>/dev/null | wc -l | tr -d ' '; }
count_users_paths() { printf '%s' "$1" | grep -oE '/Users/[A-Za-z0-9._-]+' 2>/dev/null | wc -l | tr -d ' '; }

[ "$(count_dashes "$new")" -gt "$(count_dashes "$old")" ] &&
  deny "this edit adds an em or en dash to a committed file (AGENTS.md hard boundary). Rewrite with a period, comma, colon, hyphen, or parentheses."

[ "$(count_users_paths "$new")" -gt "$(count_users_paths "$old")" ] &&
  deny "this edit adds a machine-specific /Users/<name> path to a committed file (AGENTS.md hard boundary). Use \$HOME, ~, \$HOMEBREW_PREFIX, \$XDG_*, or a repo-relative path."

exit 0
