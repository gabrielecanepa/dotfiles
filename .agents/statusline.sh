#!/bin/bash

input=$(cat)
model=$(jq -r '.model.display_name // "Claude"' <<<"$input")
dir=$(jq -r '.workspace.current_dir // "."' <<<"$input")
style=$(jq -r '.output_style.name // empty' <<<"$input")
branch=$(git -C "$dir" branch --show-current 2>/dev/null)
dirty=""
[ -n "$branch" ] && [ -n "$(git -C "$dir" status --porcelain 2>/dev/null | head -1)" ] && dirty="*"

dim=$'\e[2m'
cyan=$'\e[36m'
green=$'\e[32m'
reset=$'\e[0m'

[[ $dir == "$HOME"* ]] && dir="~${dir#"$HOME"}"
line="${cyan}${model}${reset} ${dim}·${reset} ${dir}"
[ -n "$branch" ] && line+=" ${dim}·${reset} ${green}${branch}${dirty}${reset}"
[ -n "$style" ] && [ "$style" != "default" ] && line+=" ${dim}·${reset} ${style}"
printf '%s\n' "$line"
