#!/usr/bin/env bash

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')

gradient_color() {
  local i=$1
  local r1=255 g1=194 b1=0
  local r2=246 g2=28 b2=27
  local r=$((r1 + (r2 - r1) * i / 9))
  local g=$((g1 + (g2 - g1) * i / 9))
  local b=$((b1 + (b2 - b1) * i / 9))
  printf '%d;%d;%d' "$r" "$g" "$b"
}

render_bar() {
  local pct=$1
  local width=10
  local filled=$(((pct * width + 50) / 100))
  [[ "$filled" -gt "$width" ]] && filled=$width
  local bar=""
  local i=0
  while [[ "$i" -lt "$width" ]]; do
    if [[ "$i" -lt "$filled" ]]; then
      bar="${bar}\033[38;2;$(gradient_color "$i")m▓"
    else
      bar="${bar}\033[0m░"
    fi
    i=$((i + 1))
  done
  bar="${bar}\033[0m"
  printf '%b' "$bar"
}

format_pct() {
  local raw=$1
  local fmt
  fmt=$(printf '%.1f' "$raw")
  fmt=${fmt%.0}
  printf '%s%%' "$fmt"
}

format_remaining() {
  local resets_at=$1
  local now
  now=$(date +%s)
  local rem=$((resets_at - now))
  if [[ "$rem" -le 0 ]]; then
    printf 'now'
    return
  fi
  local d=$((rem / 86400))
  local h=$(((rem % 86400) / 3600))
  local m=$(((rem % 3600) / 60))
  local out=""
  [[ "$d" -gt 0 ]] && out="${out}${d}d"
  { [[ "$d" -gt 0 ]] || [[ "$h" -gt 0 ]]; } && out="${out}${h}h"
  out="${out}${m}m"
  printf '%s' "$out"
}

CACHE_FILE="/tmp/statusline-git-cache-${session_id}"
CACHE_TTL=5
now_epoch=$(date +%s)
cache_valid=false

if [[ -f "$CACHE_FILE" ]]; then
  # Linux stat form first, macOS -f %m as fallback
  cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
  if [[ -n "$cache_mtime" ]] && [[ $((now_epoch - cache_mtime)) -lt "$CACHE_TTL" ]]; then
    cache_valid=true
  fi
fi

if [[ "$cache_valid" = true ]]; then
  IFS='|' read -r branch staged modified deleted <"$CACHE_FILE"
else
  branch=$(cd "$cwd" 2>/dev/null && git branch --show-current 2>/dev/null)
  staged=$(cd "$cwd" 2>/dev/null && git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(cd "$cwd" 2>/dev/null && git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  deleted=$(cd "$cwd" 2>/dev/null && git diff --diff-filter=D --name-only 2>/dev/null | wc -l | tr -d ' ')
  staged=${staged:-0}
  modified=${modified:-0}
  deleted=${deleted:-0}
  printf '%s|%s|%s|%s' "$branch" "$staged" "$modified" "$deleted" >"$CACHE_FILE"
fi

host=$(echo "$input" | jq -r '.workspace.repo.host // empty')
owner=$(echo "$input" | jq -r '.workspace.repo.owner // empty')
name=$(echo "$input" | jq -r '.workspace.repo.name // empty')

line1=""
if [[ -n "$owner" ]] && [[ -n "$name" ]]; then
  if [[ -n "$host" ]]; then
    # OSC 8 hyperlink: ESC]8;;<URL>BEL<TEXT>ESC]8;;BEL
    line1=$(printf '\033]8;;https://%s/%s/%s\a%s/%s\033]8;;\a' "$host" "$owner" "$name" "$owner" "$name")
  else
    line1="${owner}/${name}"
  fi
elif [[ -n "$cwd" ]]; then
  line1=$(basename "$cwd")
fi

if [[ -n "$branch" ]]; then
  line1="${line1} ${branch}"
fi

status=""
[[ "$staged" -gt 0 ]] 2>/dev/null && status="${status}\033[32m+${staged}\033[0m"
[[ "$modified" -gt 0 ]] 2>/dev/null && status="${status}\033[33m~${modified}\033[0m"
[[ "$deleted" -gt 0 ]] 2>/dev/null && status="${status}\033[31m-${deleted}\033[0m"
if [[ -n "$status" ]]; then
  line1="${line1} $(printf '%b' "$status")"
fi

model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

line2=$(printf '\033[1;38;5;173m%s\033[0m' "$model")
[[ -n "$effort" ]] && line2="${line2} ${effort}"

five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

line3=""
if [[ -n "$five_hour_pct" ]] && [[ -n "$five_hour_resets" ]]; then
  five_hour_bar=$(render_bar "${five_hour_pct%.*}")
  five_hour_fmt=$(format_pct "$five_hour_pct")
  five_hour_rem=$(format_remaining "$five_hour_resets")
  line3=$(printf '5-hour  %b  %s \033[2m%s\033[0m' "$five_hour_bar" "$five_hour_fmt" "$five_hour_rem")
fi

line4=""
if [[ -n "$seven_day_pct" ]] && [[ -n "$seven_day_resets" ]]; then
  seven_day_bar=$(render_bar "${seven_day_pct%.*}")
  seven_day_fmt=$(format_pct "$seven_day_pct")
  seven_day_rem=$(format_remaining "$seven_day_resets")
  line4=$(printf 'weekly  %b  %s \033[2m%s\033[0m' "$seven_day_bar" "$seven_day_fmt" "$seven_day_rem")
fi

printf '%b\n%b' "$line1" "$line2"
[[ -n "$line3" ]] && printf '\n%b' "$line3"
[[ -n "$line4" ]] && printf '\n%b' "$line4"
printf '\n'
