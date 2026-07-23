#!/usr/bin/env bash
#
# Claude Code subagent statusline.

set -uo pipefail

input=$(cat)

echo "$input" | jq -c '
  .tasks[] |
  ([.name, .label, .type, "task"] | map(select(. != null and . != "")) | first) as $label |
  (.tokenCount // null) as $tokens |
  (.contextWindowSize // null) as $size |
  {
    id: .id,
    content: (
      if ($tokens != null and $size != null and $size > 0) then
        (($tokens * 100 / $size) | floor) as $pct |
        ([(($pct * 8 / 100) | floor), 8] | min) as $filled |
        ([range(0; 8) | if . < $filled then "▓" else "░" end] | join("")) as $bar |
        ($label + " " + $bar + " " + ($pct | tostring) + "% " + (($tokens / 1000 | floor | tostring) + "k"))
      elif ($tokens != null) then
        ($label + " " + (($tokens / 1000 | floor | tostring) + "k tok"))
      else
        $label
      end
    )
  }
'
