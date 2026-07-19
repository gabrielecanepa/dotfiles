#!/usr/bin/env bash
#
# Dispatcher: selects a statusline variant from ~/.claude/statuslines/.
# Override with CLAUDE_STATUSLINE=<name> (e.g. agent, gradient).
set -uo pipefail

variant="${CLAUDE_STATUSLINE:-agent}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/statuslines"
target="$dir/$variant.sh"
[[ -x "$target" ]] || target="$dir/gradient.sh"
exec "$target" "$@"
