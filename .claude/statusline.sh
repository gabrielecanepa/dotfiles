#!/usr/bin/env bash
#
# Claude Code statusline, configured by CLAUDE_STATUSLINE_CONFIG (default: ~/.claude/statusline.json).
# Every key is optional and an invalid value falls back to its default; /statusline-config validates
# and sets them, and statusline.schema.json describes the same shape for editors:
#   theme          default|mono; mono strips all colors but keeps dim
#   layout         array of lines, each an array of segment names, e.g. [["repo","branch"],["model"]]
#   bar.style      solid|dotted|dots|gradient|pacman (default: solid)
#   bar.trail      true leaves small dots behind the pacman head instead of spaces (pacman only)
#   effort.style   colored|raw|symbol; colored word, plain word, or the CLI model picker glyph
#   context.style  inline|progress (default: inline); dim tokens on the model line, or a bar line
#   context.warn   none|color|icon|both (default: none); as the window fills up, color tints
#                  the token count yellow/orange/red and icon appends context.icon in that color
#   context.icon   icon appended when warn is icon or both (default: ⚠)
# Segments: repo branch status model effort fast-mode context five-hour seven-day.

set -uo pipefail

# Colors
COLOR_ACCENT="38;2;10;145;178"
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
GLYPH_FILL_SHADE="\xe2\x96\x93"             # ▓ U+2593
GLYPH_EMPTY_SHADE="\xe2\x96\x91"            # ░ U+2591
GLYPH_BRAILLE_FULL="\xe2\xa3\xbf"           # ⣿ U+28FF
GLYPH_DOT="\xe2\x80\xa2"                    # • U+2022
GLYPH_MIDDLE_DOT="\xc2\xb7"                 # · U+00B7
GLYPH_PACMAN="\xe1\x97\xa7"                 # ᗧ U+15E7
GLYPH_BOLT="\xe2\x9a\xa1\xef\xb8\x8e"       # ⚡ U+26A1 + U+FE0E
GLYPH_WARN_ICON=$'\xe2\x9a\xa0\xef\xb8\x8e' # ⚠ U+26A0 + U+FE0E

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

# Context thresholds
CONTEXT_WARN_TOKENS=100000
CONTEXT_HIGH_TOKENS=150000
CONTEXT_CRIT_TOKENS=250000
CONTEXT_WARN_PCT=50
CONTEXT_HIGH_PCT=70
CONTEXT_CRIT_PCT=85

# Context colors
COLOR_CONTEXT_WARN="33"       # yellow
COLOR_CONTEXT_HIGH="38;5;208" # orange
COLOR_CONTEXT_CRIT="31"       # red

# Defaults
BAR_WIDTH=10
CACHE_TTL=5

# Settings
# Read from CLAUDE_STATUSLINE_CONFIG. A missing file, malformed JSON, a wrongly typed value or
# an unknown name leave the variable empty and falls back to its default.
CONFIG_FILE="${CLAUDE_STATUSLINE_CONFIG:-$HOME/.claude/statusline.json}"
theme="" layout="" bar_style="" bar_trail="" effort_style="" context_style="" context_warn="" context_icon=""
if [[ -r "$CONFIG_FILE" ]]; then
  {
    IFS= read -r theme
    IFS= read -r layout
    IFS= read -r bar_style
    IFS= read -r bar_trail
    IFS= read -r effort_style
    IFS= read -r context_style
    IFS= read -r context_warn
    IFS= read -r context_icon
  } < <(jq -r '
    def obj(f): (f | if type == "object" then . else {} end);
    def str(f): (f | if type == "string" then gsub("[\r\n\t]"; " ") else "" end);
    def flag(f): (f | if type == "boolean" then tostring else "" end);
    def lines(f): (f | if type == "array" then
        [.[] | if type == "array" then [.[] | strings] | join(" ") else empty end] | join(" / ")
      else "" end);
    str(.theme),
    lines(.layout),
    str(obj(.bar) | .style),
    flag(obj(.bar) | .trail),
    str(obj(.effort) | .style),
    str(obj(.context) | .style),
    str(obj(.context) | .warn),
    str(obj(.context) | .icon)
  ' "$CONFIG_FILE" 2>/dev/null)
fi
theme="${theme:-default}"
bar_style="${bar_style:-solid}"
bar_trail="${bar_trail:-false}"
effort_style="${effort_style:-colored}"
context_style="${context_style:-inline}"
context_icon="${context_icon:-$GLYPH_WARN_ICON}"
case "$context_warn" in
  color | icon | both) ;;
  *) context_warn="none" ;;
esac

# Layout
# Which segments to show and in what order, / starts a new line.
# Override with the "layout" key in the config file, unknown names are dropped and a
# layout with no remaining segment falls back to the default.
STATUSLINE_LAYOUT=(repo branch status / model effort fast-mode context / five-hour / seven-day)
[[ "$context_style" = "progress" ]] && STATUSLINE_LAYOUT=(repo branch status / model effort fast-mode / context / five-hour / seven-day)
if [[ -n "$layout" ]]; then
  read -r -a layout_tokens <<<"$layout"
  custom_layout=()
  has_segment=false
  for token in ${layout_tokens[@]+"${layout_tokens[@]}"}; do
    case "$token" in
      repo | branch | status | model | effort | fast-mode | context | five-hour | seven-day | /)
        custom_layout+=("$token")
        [[ "$token" != / ]] && has_segment=true
        ;;
    esac
  done
  [[ "$has_segment" = true ]] && STATUSLINE_LAYOUT=("${custom_layout[@]}")
fi

# Theme
# Strip colors in mono theme, keep dim and bold.
if [[ "$theme" = "mono" ]]; then
  COLOR_ACCENT=""
  COLOR_PACMAN=""
  COLOR_MODEL="1"
  COLOR_ADDED=""
  COLOR_MODIFIED=""
  COLOR_DELETED=""
  COLOR_CONTEXT_WARN=""
  COLOR_CONTEXT_HIGH=""
  COLOR_CONTEXT_CRIT=""
fi

# Settings
# Parse every field in one jq call. Percentages/tokens default to 0, rate-limit
# fields are empty so the segments can hide.
input=$(cat)
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

# Print a color along the gradient from GRADIENT_FROM_RGB to GRADIENT_TO_RGB for step i of 10 (0-based).
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
  [[ "$bar_trail" = "true" ]] &&
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
  if [[ "$bar_style" = "pacman" ]]; then
    render_pacman_bar "$width" "$filled"
    return
  fi
  local fill_char="$GLYPH_FILL_SHADE" empty_char="$GLYPH_EMPTY_SHADE"
  if [[ "$bar_style" = "dotted" ]]; then
    fill_char="$GLYPH_BRAILLE_FULL"
    empty_char="$GLYPH_BRAILLE_FULL"
  elif [[ "$bar_style" = "dots" ]]; then
    fill_char="$GLYPH_DOT"
    empty_char="$GLYPH_DOT"
  fi
  local bar=""
  local i=0
  while [[ "$i" -lt "$width" ]]; do
    if [[ "$i" -lt "$filled" ]]; then
      if [[ "$bar_style" = "gradient" ]] && [[ "$theme" != "mono" ]]; then
        bar="${bar}\033[38;2;$(gradient_color "$i")m${fill_char}"
      elif [[ "$bar_style" = "dotted" || "$bar_style" = "dots" ]]; then
        bar="${bar}\033[${COLOR_ACCENT}m${fill_char}"
      else
        bar="${bar}${fill_char}"
      fi
    else
      if [[ "$bar_style" = "dotted" || "$bar_style" = "dots" ]]; then
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

context_threshold() {
  local tokens=$1 pct=$2
  local scaled=$((context_size * pct / 100))
  if [[ "$context_size" -gt 0 ]] && [[ "$scaled" -lt "$tokens" ]]; then
    printf '%s' "$scaled"
  else
    printf '%s' "$tokens"
  fi
}

context_level() {
  if [[ "$context_tokens" -ge "$(context_threshold "$CONTEXT_CRIT_TOKENS" "$CONTEXT_CRIT_PCT")" ]]; then
    printf 'crit'
  elif [[ "$context_tokens" -ge "$(context_threshold "$CONTEXT_HIGH_TOKENS" "$CONTEXT_HIGH_PCT")" ]]; then
    printf 'high'
  elif [[ "$context_tokens" -ge "$(context_threshold "$CONTEXT_WARN_TOKENS" "$CONTEXT_WARN_PCT")" ]]; then
    printf 'warn'
  fi
}

context_color() {
  case "$1" in
    crit) printf '%s' "$COLOR_CONTEXT_CRIT" ;;
    high) printf '%s' "$COLOR_CONTEXT_HIGH" ;;
    warn) printf '%s' "$COLOR_CONTEXT_WARN" ;;
  esac
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
  local label=$1 pct=$2 detail=$3 color=${4:-$DIM}
  local bar fmt
  bar=$(render_bar "${pct%.*}")
  fmt=$(format_pct "$pct")
  printf '%-7s %b %s \033[%sm%s\033[%sm' "$label" "$bar" "$fmt" "$color" "$detail" "$RESET"
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

# Strip a parenthesized suffix from the model name, e.g. Opus 4.8 (1M context) -> Opus 4.8.
model=${model% (*)}

# Segments: each prints its rendered content (including its own left separator) or nothing.
segment_repo() {
  local text="" link=""
  if [[ -n "$owner" ]] && [[ -n "$name" ]]; then
    text="$owner/$name"
    [[ -n "$host" ]] && link="https://$host/$owner/$name"
  elif [[ -n "$cwd" ]]; then
    text=$(basename "$cwd")
  fi
  [[ -z "$text" ]] && return
  [[ -n "$COLOR_ACCENT" ]] && printf '\033[%sm' "$COLOR_ACCENT"
  # OSC 8 hyperlink: ESC]8;;<URL>BEL<TEXT>ESC]8;;BEL
  [[ -n "$link" ]] && printf '\033]8;;%s\a' "$link"
  printf '%s' "$text"
  [[ -n "$link" ]] && printf '\033]8;;\a'
  [[ -n "$COLOR_ACCENT" ]] && printf '\033[%sm' "$RESET"
  return 0
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
  if [[ "$effort_style" = "symbol" ]]; then
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
  if [[ "$effort_style" = "raw" ]] || [[ "$theme" = "mono" ]]; then
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
  local detail color icon="" level=""
  detail=$(format_tokens "$context_tokens")
  [[ -z "$detail" ]] && return
  [[ "$context_size" -gt 0 ]] 2>/dev/null && detail="${detail}/$(format_tokens "$context_size")"
  [[ "$context_warn" != "none" ]] && level=$(context_level)
  color=$(context_color "$level")
  if [[ -n "$level" ]] && [[ "$context_warn" = "icon" || "$context_warn" = "both" ]]; then
    icon=$(printf ' \033[%sm%s\033[%sm' "${color:-$RESET}" "$context_icon" "$RESET")
  fi
  [[ "$context_warn" = "color" || "$context_warn" = "both" ]] || color=""
  color=${color:-$DIM}
  if [[ "$context_style" = "progress" ]]; then
    render_usage_line "context" "$context_pct" "$detail" "$color"
  else
    printf ' \033[%sm%s\033[%sm' "$color" "$detail" "$RESET"
  fi
  printf '%s' "$icon"
}

segment_five_hour() {
  [[ -n "$five_hour_pct" ]] && [[ -n "$five_hour_resets" ]] &&
    render_usage_line "5-hour" "$five_hour_pct" "$(format_remaining "$five_hour_resets")"
}

segment_seven_day() {
  [[ -n "$seven_day_pct" ]] && [[ -n "$seven_day_resets" ]] &&
    render_usage_line "weekly" "$seven_day_pct" "$(format_remaining "$seven_day_resets")"
}

# Walk STATUSLINE_LAYOUT: concatenate segments per line, / breaks lines, drop empty lines.
# Segments carry their own left separator, so the one opening a line has it stripped.
render_statusline() {
  local out="" line="" seg rendered has_line=false first_line=true dot
  dot=$(printf '\033[%sm%b\033[%sm' "$DIM" "$GLYPH_MIDDLE_DOT" "$RESET")
  for seg in "${STATUSLINE_LAYOUT[@]}"; do
    if [[ "$seg" = / ]]; then
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
    if [[ -z "$line" ]]; then
      rendered="${rendered# }"
      rendered="${rendered#"$dot"}"
    fi
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
