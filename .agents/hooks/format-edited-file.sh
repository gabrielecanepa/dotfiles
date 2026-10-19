#!/bin/sh
#
# PostToolUse (Edit|Write|MultiEdit): run the repository formatters on the
# edited files, only when the repository has a  matching config (oxfmt ->
# .oxfmtrc.json, rubocop -> .rubocop.yml, shfmt -> .editorconfig).
# shfmt covers sh and bash only and `--apply-ignore` follows the .editorconfig
# ignore sections.
# Fails open: missing jq, file, git root, config, or binary is a no-op.

set -u

case ":$PATH:" in
  *:/opt/homebrew/bin:*) ;;
  *) PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" ;;
esac

input="$(cat)"
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
[ -f "$fp" ] || exit 0

root="$(git -C "$(dirname "$fp")" rev-parse --show-toplevel 2>/dev/null)"
[ -n "$root" ] || exit 0

case "$fp" in
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.css | *.json | *.md | *.mdx)
    [ -f "$root/.oxfmtrc.json" ] && command -v oxfmt >/dev/null 2>&1 &&
      oxfmt "$fp" >/dev/null 2>&1
    ;;
  *.rb)
    [ -f "$root/.rubocop.yml" ] && command -v rubocop >/dev/null 2>&1 &&
      rubocop --autocorrect --format quiet "$fp" >/dev/null 2>&1
    ;;
  *.sh | *.bash)
    [ -f "$root/.editorconfig" ] && command -v shfmt >/dev/null 2>&1 &&
      shfmt --apply-ignore -w "$fp" >/dev/null 2>&1
    ;;
esac

exit 0
