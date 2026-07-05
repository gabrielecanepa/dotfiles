#!/bin/sh

# PostToolUse (Edit|Write|MultiEdit): run the repo's own formatter on the edited
# file so style compliance is deterministic instead of prompt-enforced. Fires only
# when the repo declares the matching config (oxfmt -> .oxfmtrc.json at the git
# root, rubocop -> .rubocop.yml, shfmt -> .editorconfig); shfmt covers sh/bash
# only and --apply-ignore honors the .editorconfig ignore sections, so zsh is
# never formatted. Fails open: missing jq, file, git root, config, or binary is
# a no-op.

case ":$PATH:" in
  *:/opt/homebrew/bin:*) ;;
  *) PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" ;;
esac

input="$(cat)"
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
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
