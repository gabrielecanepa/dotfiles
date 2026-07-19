#!/usr/bin/env bash
#
# Claude Code statusline, configured by CLAUDE_STATUSLINE_CONFIG (default: ~/.claude/statusline.json).
# Keys, all optional:
#   style    solid|dotted|dots|gradient|pacman (default: solid), set live with /statusline-style
#   layout   space-separated segment names with "|" as a line break, e.g. "repo branch | model effort | context"
#   theme    default|mono; mono strips all colors but keeps dim
#   pacman   default|trailing; trailing leaves small dots behind the pacman instead of spaces
#   effort   colored|raw|symbol; colored word, plain word, or the CLI model picker glyph
#   context  inline|progress (default: inline); dim tokens on the model line, or a bar line
# Segments: repo branch status model effort fast-mode context five_hour seven_day.
#

set -uo pipefail

# Colors
COLOR_BLUE="38;2;91;104;238"
COLOR_PACMAN="38;2;230;170;20"
COLOR_MODEL="1;38;5;173"
COLOR_ADDED="32"
COLOR_MODIFIED="33"
COLOR_DELETED="31"
COLOR_CLAUDE="38;2;215;119;87"
COLOR_FAST_MODE="33"
GRADIENT_FROM_RGB="255 194 0"
GRADIENT_TO_RGB="246 28 27"
DIM="2"
RESET="0"

# Glyphs
GLYPH_FILL_SHADE="\xe2\x96\x93"       # ▓ U+2593
GLYPH_EMPTY_SHADE="\xe2\x96\x91"      # ░ U+2591
GLYPH_BRAILLE_FULL="\xe2\xa3\xbf"     # ⣿ U+28FF
GLYPH_DOT="\xe2\x80\xa2"              # • U+2022
GLYPH_MIDDLE_DOT="\xc2\xb7"           # · U+00B7
GLYPH_PACMAN="\xe1\x97\xa7"           # ᗧ U+15E7
GLYPH_BOLT="\xe2\x9a\xa1\xef\xb8\x8e" # ⚡ U+26A1 + U+FE0E

# Effort colors
COLOR_EFFORT_LOW="33"         # yellow
COLOR_EFFORT_MEDIUM="32"      # green
COLOR_EFFORT_HIGH="34"        # blue
COLOR_EFFORT_XHIGH="38;5;135" # purple

# Effort glyphs
GLYPH_EFFORT_LOW="\xe2\x97\x8b"    # ○ U+25CB
GLYPH_EFFORT_MEDIUM="\xe2\x97\x90" # ◐ U+25D0
GLYPH_EFFORT_HIGH="\xe2\x97\x8f"   # ● U+25CF
GLYPH_EFFORT_XHIGH="\xe2\x97\x89"  # ◉ U+25C9
GLYPH_EFFORT_MAX="\xe2\x97\x88"    # ◈ U+25C8

# Defaults
BAR_WIDTH=10
CACHE_TTL=5

# Settings
# Read from CLAUDE_STATUSLINE_CONFIG, missing or unknown values fall back to defaults.
CONFIG_FILE="${CLAUDE_STATUSLINE_CONFIG:-$HOME/.claude/statusline.json}"
style="" layout="" theme="" pacman_mode="" effort_display="" context_mode=""
if [[ -r "$CONFIG_FILE" ]]; then
  {
    IFS= read -r style
    IFS= read -r layout
    IFS= read -r theme
    IFS= read -r pacman_mode
    IFS= read -r effort_display
    IFS= read -r context_mode
  } < <(jq -r '
    def s(f): f | if type == "string" then gsub("[\r\n\t]"; " ") else "" end;
    s(.style), s(.layout), s(.theme), s(.pacman), s(.effort), s(.context)
  ' "$CONFIG_FILE" 2>/dev/null)
fi
style="${style:-solid}"
theme="${theme:-default}"
pacman_mode="${pacman_mode:-default}"
effort_display="${effort_display:-colored}"
context_mode="${context_mode:-inline}"

# Layout
# Which segments to show and in what order, "|" starts a new line.
# Override with the "layout" key in the config file, unknown names are dropped and a
# layout with no remaining segment falls back to the default.
STATUSLINE_LAYOUT=(repo branch status "|" model effort fast-mode context "|" five_hour "|" seven_day)
[[ "$context_mode" = "progress" ]] &&
  STATUSLINE_LAYOUT=(repo branch status "|" model effort fast-mode "|" context "|" five_hour "|" seven_day)
if [[ -n "$layout" ]]; then
  read -r -a layout_tokens <<<"$layout"
  custom_layout=()
  has_segment=false
  for tok in ${layout_tokens[@]+"${layout_tokens[@]}"}; do
    case "$tok" in
      repo | branch | status | model | effort | fast-mode | context | five_hour | seven_day | "|")
        custom_layout+=("$tok")
        [[ "$tok" != "|" ]] && has_segment=true
        ;;
    esac
  done
  [[ "$has_segment" = true ]] && STATUSLINE_LAYOUT=("${custom_layout[@]}")
fi

# Mono theme: strip colors, keep dim and bold.
if [[ "$theme" = "mono" ]]; then
  COLOR_BLUE=""
  COLOR_PACMAN=""
  COLOR_MODEL="1"
  COLOR_ADDED=""
  COLOR_MODIFIED=""
  COLOR_DELETED=""
fi

input=$(cat)

# Parse every field in one jq call.
# Percentages/tokens default to 0, rate-limit fields are empty so the segments can hide.
{
  IFS= read -r session_id
  IFS= read -r cwd
  IFS= read -r host
  IFS= read -r owner
  IFS= read -r name
  IFS= read -r model
  IFS= read -r effort
  IFS= read -r fast_mode
  IFS= read -r context_pct
  IFS= read -r context_tokens
  IFS= read -r context_size
  IFS= read -r five_hour_pct
  IFS= read -r five_hour_resets
  IFS= read -r seven_day_pct
  IFS= read -r seven_day_resets
} < <(printf '%s' "$input" | jq -r '
  .session_id // "",
  .workspace.current_dir // "",
  .workspace.repo.host // "",
  .workspace.repo.owner // "",
  .workspace.repo.name // "",
  .model.display_name // "",
  .effort.level // "",
  (.fast_mode == true | tostring),
  (.context_window.used_percentage // 0 | tostring),
  (.context_window.total_input_tokens // 0 | tostring),
  (.context_window.context_window_size // 0 | tostring),
  (.rate_limits.five_hour.used_percentage // "" | tostring),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.used_percentage // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring)
')

gradient_color() {
  local i=$1
  local r1 g1 b1 r2 g2 b2
  read -r r1 g1 b1 <<<"$GRADIENT_FROM_RGB"
  read -r r2 g2 b2 <<<"$GRADIENT_TO_RGB"
  local r=$((r1 + (r2 - r1) * i / 9))
  local g=$((g1 + (g2 - g1) * i / 9))
  local b=$((b1 + (b2 - b1) * i / 9))
  printf '%d;%d;%d' "$r" "$g" "$b"
}

# Interpolate a two-color RGB ramp: prints "r;g;b" for step i of steps (0-based).
ramp_rgb() {
  local i=$1 steps=$2 r1 g1 b1 r2 g2 b2
  read -r r1 g1 b1 <<<"$3"
  read -r r2 g2 b2 <<<"$4"
  local d=$((steps > 1 ? steps - 1 : 1))
  printf '%d;%d;%d' \
    $((r1 + (r2 - r1) * i / d)) \
    $((g1 + (g2 - g1) * i / d)) \
    $((b1 + (b2 - b1) * i / d))
}

# Color each character of $text along a three-stop gradient (from -> mid -> to).
ramp_text() {
  local text=$1 bold=$2 from=$3 mid=$4 to=$5
  local len=${#text} out="" i=0
  # First half interpolates from->mid, second half mid->to.
  local mididx=$(((len - 1) / 2))
  while [[ "$i" -lt "$len" ]]; do
    local rgb
    if [[ "$i" -le "$mididx" ]] && [[ "$mididx" -gt 0 ]]; then
      rgb=$(ramp_rgb "$i" $((mididx + 1)) "$from" "$mid")
    elif [[ "$mididx" -lt $((len - 1)) ]]; then
      rgb=$(ramp_rgb $((i - mididx)) $((len - mididx)) "$mid" "$to")
    else
      rgb=$(ramp_rgb "$i" "$len" "$from" "$to")
    fi
    out="${out}\033[${bold}38;2;${rgb}m${text:i:1}"
    i=$((i + 1))
  done
  printf '%s\033[%sm' "$out" "$RESET"
}

render_effort_max() {
  local word=$1
  printf ' %b' "$(ramp_text "$word" "1;" "150 90 255" "230 90 200" "255 110 120")"
}

render_pacman_bar() {
  local width=$1 filled=$2
  local head="\033[${COLOR_PACMAN}m${GLYPH_PACMAN}\033[${RESET}m"
  local pellet="\033[${RESET}m\033[${DIM}m${GLYPH_DOT}\033[${RESET}m"
  local trail=" "
  [[ "$pacman_mode" = "trailing" ]] &&
    trail="\033[${RESET}m\033[${DIM}m${GLYPH_MIDDLE_DOT}\033[${RESET}m"
  local bar=""
  local i=0
  while [[ "$i" -lt "$width" ]]; do
    if [[ "$filled" -gt 0 ]] && [[ "$i" -eq $((filled - 1)) ]]; then
      bar="${bar}${head}"
    elif [[ "$i" -lt "$filled" ]]; then
      bar="${bar}${trail}"
    else
      bar="${bar}${pellet}"
    fi
    i=$((i + 1))
  done
  bar="${bar}\033[${RESET}m"
  printf '%b' "$bar"
}

render_bar() {
  local pct=$1
  local width=$BAR_WIDTH
  local filled=$(((pct * width + 50) / 100))
  [[ "$filled" -gt "$width" ]] && filled=$width
  if [[ "$style" = "pacman" ]]; then
    render_pacman_bar "$width" "$filled"
    return
  fi
  local fill_char="$GLYPH_FILL_SHADE" empty_char="$GLYPH_EMPTY_SHADE"
  if [[ "$style" = "dotted" ]]; then
    fill_char="$GLYPH_BRAILLE_FULL"
    empty_char="$GLYPH_BRAILLE_FULL"
  elif [[ "$style" = "dots" ]]; then
    fill_char="$GLYPH_DOT"
    empty_char="$GLYPH_DOT"
  fi
  local bar=""
  local i=0
  while [[ "$i" -lt "$width" ]]; do
    if [[ "$i" -lt "$filled" ]]; then
      if [[ "$style" = "gradient" ]] && [[ "$theme" != "mono" ]]; then
        bar="${bar}\033[38;2;$(gradient_color "$i")m${fill_char}"
      elif [[ "$style" = "dotted" || "$style" = "dots" ]]; then
        bar="${bar}\033[${COLOR_BLUE}m${fill_char}"
      else
        bar="${bar}${fill_char}"
      fi
    else
      if [[ "$style" = "dotted" || "$style" = "dots" ]]; then
        bar="${bar}\033[${RESET}m\033[${DIM}m${empty_char}"
      else
        bar="${bar}\033[${RESET}m${empty_char}"
      fi
    fi
    i=$((i + 1))
  done
  bar="${bar}\033[${RESET}m"
  printf '%b' "$bar"
}

format_pct() {
  local raw=$1
  local fmt
  fmt=$(printf '%.1f' "$raw")
  fmt=${fmt%.0}
  printf '%s%%' "$fmt"
}

format_tokens() {
  local n=$1
  local whole frac unit
  if [[ "$n" -ge 1000000 ]]; then
    whole=$((n / 1000000))
    frac=$(((n % 1000000) / 100000))
    unit=M
  elif [[ "$n" -ge 1000 ]]; then
    whole=$((n / 1000))
    frac=$(((n % 1000) / 100))
    unit=k
  else
    printf '%s' "$n"
    return
  fi
  if [[ "$frac" -eq 0 ]]; then
    printf '%s%s' "$whole" "$unit"
  else
    printf '%s.%s%s' "$whole" "$frac" "$unit"
  fi
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

render_usage_line() {
  local label=$1 pct=$2 detail=$3
  local bar fmt
  bar=$(render_bar "${pct%.*}")
  fmt=$(format_pct "$pct")
  printf '%-7s %b %s \033[%sm%s\033[%sm' "$label" "$bar" "$fmt" "$DIM" "$detail" "$RESET"
}

CACHE_FILE="/tmp/statusline-git-cache-${session_id}"
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

branch=${branch:-}
staged=${staged:-0}
modified=${modified:-0}
deleted=${deleted:-0}

# Strip a trailing parenthetical from the model name, e.g. "Opus 4.8 (1M context)" -> "Opus 4.8".
model=${model% (*)}

# Segments: each prints its rendered content (including its own left separator) or nothing.
segment_repo() {
  if [[ -n "$owner" ]] && [[ -n "$name" ]]; then
    if [[ -n "$host" ]]; then
      # OSC 8 hyperlink: ESC]8;;<URL>BEL<TEXT>ESC]8;;BEL
      printf '\033]8;;https://%s/%s/%s\a%s/%s\033]8;;\a' "$host" "$owner" "$name" "$owner" "$name"
    else
      printf '%s/%s' "$owner" "$name"
    fi
  elif [[ -n "$cwd" ]]; then
    basename "$cwd"
  fi
}

segment_branch() {
  [[ -n "$branch" ]] && printf ' %s' "$branch"
}

segment_status() {
  local status=""
  [[ "$staged" -gt 0 ]] 2>/dev/null && status="${status}\033[${COLOR_ADDED}m+${staged}\033[${RESET}m"
  [[ "$modified" -gt 0 ]] 2>/dev/null && status="${status}\033[${COLOR_MODIFIED}m~${modified}\033[${RESET}m"
  [[ "$deleted" -gt 0 ]] 2>/dev/null && status="${status}\033[${COLOR_DELETED}m-${deleted}\033[${RESET}m"
  [[ -n "$status" ]] && printf '\033[%sm%b\033[%sm%b' "$DIM" "$GLYPH_MIDDLE_DOT" "$RESET" "$status"
}

segment_model() {
  [[ -n "$model" ]] && printf '\033[%sm%s\033[%sm' "$COLOR_MODEL" "$model" "$RESET"
}

# Effort segment: "colored" tints the level word per the CLI effort picker, "raw" prints it
# plain, "symbol" prints the CLI model picker glyph in the Claude orange.
segment_effort() {
  [[ -z "$effort" ]] && return
  if [[ "$effort_display" = "symbol" ]]; then
    local glyph
    case "$effort" in
      low) glyph="$GLYPH_EFFORT_LOW" ;;
      medium) glyph="$GLYPH_EFFORT_MEDIUM" ;;
      high) glyph="$GLYPH_EFFORT_HIGH" ;;
      xhigh) glyph="$GLYPH_EFFORT_XHIGH" ;;
      max) glyph="$GLYPH_EFFORT_MAX" ;;
      *) glyph="$GLYPH_EFFORT_HIGH" ;;
    esac
    if [[ "$theme" = "mono" ]]; then
      printf ' %b' "$glyph"
    else
      printf ' \033[%sm%b\033[%sm' "$COLOR_CLAUDE" "$glyph" "$RESET"
    fi
    return
  fi
  if [[ "$effort_display" = "raw" ]] || [[ "$theme" = "mono" ]]; then
    printf ' %s' "$effort"
    return
  fi
  case "$effort" in
    low) printf ' \033[%sm%s\033[%sm' "$COLOR_EFFORT_LOW" "$effort" "$RESET" ;;
    medium) printf ' \033[%sm%s\033[%sm' "$COLOR_EFFORT_MEDIUM" "$effort" "$RESET" ;;
    high) printf ' \033[%sm%s\033[%sm' "$COLOR_EFFORT_HIGH" "$effort" "$RESET" ;;
    xhigh) printf ' \033[%sm%s\033[%sm' "$COLOR_EFFORT_XHIGH" "$effort" "$RESET" ;;
    max) render_effort_max "$effort" ;;
    *) printf ' %s' "$effort" ;;
  esac
}

segment_fast_mode() {
  [[ "$fast_mode" = "true" ]] || return 0
  if [[ "$theme" = "mono" ]]; then
    printf ' %b' "$GLYPH_BOLT"
  else
    printf ' \033[%sm%b\033[%sm' "$COLOR_FAST_MODE" "$GLYPH_BOLT" "$RESET"
  fi
}

segment_context() {
  local detail
  detail=$(format_tokens "$context_tokens")
  [[ -z "$detail" ]] && return
  [[ "$context_size" -gt 0 ]] 2>/dev/null && detail="${detail}/$(format_tokens "$context_size")"
  if [[ "$context_mode" = "progress" ]]; then
    render_usage_line "context" "$context_pct" "$detail"
  else
    printf ' \033[%sm%s\033[%sm' "$DIM" "$detail" "$RESET"
  fi
}

segment_five_hour() {
  [[ -n "$five_hour_pct" ]] && [[ -n "$five_hour_resets" ]] &&
    render_usage_line "5-hour" "$five_hour_pct" "$(format_remaining "$five_hour_resets")"
}

segment_seven_day() {
  [[ -n "$seven_day_pct" ]] && [[ -n "$seven_day_resets" ]] &&
    render_usage_line "weekly" "$seven_day_pct" "$(format_remaining "$seven_day_resets")"
}

# Walk STATUSLINE_LAYOUT: concatenate segments per line, "|" breaks lines, drop empty lines.
render_statusline() {
  local out="" line="" seg rendered has_line=false first_line=true
  for seg in "${STATUSLINE_LAYOUT[@]}"; do
    if [[ "$seg" = "|" ]]; then
      if [[ "$has_line" = true ]]; then
        [[ "$first_line" = false ]] && out="${out}\n"
        out="${out}${line}"
        first_line=false
      fi
      line=""
      has_line=false
      continue
    fi
    rendered=$("segment_${seg//-/_}" 2>/dev/null)
    [[ -z "$rendered" ]] && continue
    line="${line}${rendered}"
    has_line=true
  done
  if [[ "$has_line" = true ]]; then
    [[ "$first_line" = false ]] && out="${out}\n"
    out="${out}${line}"
  fi
  printf '%b\n' "$out"
}

render_statusline
