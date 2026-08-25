#!/usr/bin/env bash
#
# Claude Code subagent statusline, configured by the "subagent" key of CLAUDE_STATUSLINE_CONFIG
# (default: ~/.claude/statusline.json). Every key is optional and an invalid value falls back to
# its default. /statusline-config validates and sets them, and statusline.schema.json describes
# the same shape for editors:
#   subagent.layout               groups of segment names joined by the separator,
#                                 e.g. [["title"],["model","effort","context"]]
#   subagent.separator            symbol between layout groups (default: ·); "" or " " joins
#                                 the groups with a single space
#   subagent.context.symbol       character before the token count (default: ↓)
#   subagent.context.progressbar  true draws an eight-step usage bar at the beginning of the
#                                 context (default: false)
#   subagent.context.percentage   false drops the used percentage shown in parentheses after
#                                 the token count (default: true)
# Segments: title model effort context.

set -uo pipefail

# Settings
# A missing file, malformed JSON, a wrongly typed value or an unknown name fall back to defaults.
CONFIG_FILE="${CLAUDE_STATUSLINE_CONFIG:-$HOME/.claude/statusline.json}"
subagent="{}"
if [[ -r "$CONFIG_FILE" ]]; then
  subagent=$(jq -c '.subagent | if type == "object" then . else {} end' "$CONFIG_FILE" 2>/dev/null)
  [[ -z "$subagent" ]] && subagent="{}"
fi

input=$(cat)

printf '%s' "$input" | jq -c --argjson sub "$subagent" '
  (
    $sub.layout
    | if type == "array" then
        [.[] | if type == "array" then [.[] | strings | select(IN("title", "model", "effort", "context"))] else [] end | select(length > 0)]
      else [] end
    | if length > 0 then . else [["title"], ["model", "effort", "context"]] end
  ) as $layout |
  ($sub.separator | if type == "string" then . else "·" end) as $separator |
  (if $separator == "" or $separator == " " then " " else " " + $separator + " " end) as $joiner |
  ($sub.context | if type == "object" then . else {} end) as $ctx |
  ($ctx.symbol | if type == "string" and . != "" then . else "↓" end) as $symbol |
  ($ctx.progressbar == true) as $progressbar |
  ($ctx.percentage != false) as $percentage |
  ((.effort | objects | .level) // null) as $session_effort |
  .tasks[] |
  ([.name, .description, .label, .type, "task"] | map(select(. != null and . != "")) | first) as $title |
  (.tokenCount // null) as $tokens |
  (.contextWindowSize // null) as $size |
  (.model // null) as $model_id |
  (
    if $model_id == null then ""
    else
      (["fable", "opus", "sonnet", "haiku"] | map(select(. as $f | $model_id | contains($f))) | first)
      // ($model_id | sub("^claude-"; ""))
    end
  ) as $model |
  (
    (.effort // $session_effort) as $e |
    if $e == null then ""
    elif ($e | type) == "number" then (($e / 1000 | floor | tostring) + "k")
    else ($e | tostring)
    end
  ) as $effort |
  (
    if $tokens == null then ""
    else
      (
        if $progressbar and $size != null and $size > 0 then
          ([[(($tokens * 8 / $size) | floor), (if $tokens > 0 then 1 else 0 end)] | max, 8] | min) as $filled |
          ("████████" | .[0:$filled]) + ("░░░░░░░░" | .[0:(8 - $filled)]) + " "
        else ""
        end
      )
      + $symbol + " " + (($tokens / 1000 | floor | tostring) + "k")
      + (
        if $percentage and $size != null and $size > 0 then
          " (" + (($tokens * 100 / $size) | floor | tostring) + "%)"
        else ""
        end
      )
    end
  ) as $context |
  {title: $title, model: $model, effort: $effort, context: $context} as $segments |
  ([$layout[] | [.[] | $segments[.] | select(. != "")] | select(length > 0) | join(" ")] | join($joiner)) as $content |
  select($content != "") |
  {id: .id, content: $content}
'
