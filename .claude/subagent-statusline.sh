#!/usr/bin/env bash
#
# Dispatcher: selects a subagent statusline variant from ~/.claude/statuslines/.
# Override with CLAUDE_SUBAGENT_STATUSLINE=<name>.
set -uo pipefail

variant="${CLAUDE_SUBAGENT_STATUSLINE:-subagent}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/statuslines"
target="$dir/$variant.sh"
[[ -x "$target" ]] || target="$dir/subagent.sh"
exec "$target" "$@"
