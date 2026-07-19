---
description: Set the statusline bar style (solid, dotted, dots, gradient, pacman)
argument-hint: '[solid|dotted|dots|gradient|pacman]'
allowed-tools: Bash(sh:*)
disable-model-invocation: true
---

!`sh -c '
  set -u
  case ":$PATH:" in *:/opt/homebrew/bin:*) ;; *) PATH="/opt/homebrew/bin:$PATH" ;; esac
  config="${CLAUDE_STATUSLINE_CONFIG:-$HOME/.claude/statusline.json}"
  styles="solid dotted dots gradient pacman"
  style="${1:-}"
  bt=$(printf "\140")
  options=$(printf "%s" "$styles" | sed "s/[^ ][^ ]*/$bt&$bt/g; s/ /, /g")
  if [ -z "$style" ]; then
    printf "No style specified. Valid options are: %s.\n" "$options"; exit 0
  fi
  case " $styles " in
    *" $style "*) ;;
    *) printf "Invalid style: $style. Valid options are: %s.\n" "$options"; exit 0 ;;
  esac
  base="{}"
  [ -r "$config" ] && base=$(jq "." "$config" 2>/dev/null) && [ -n "$base" ] || base="{}"
  printf "%s" "$base" | jq --arg s "$style" ".style = \$s" >"$config.tmp" && mv "$config.tmp" "$config"
  printf "Status line style set to %s%s%s.\n" "$bt" "$style" "$bt"
' -- $ARGUMENTS`

Output the line above verbatim as your entire reply, with nothing added before or after.
