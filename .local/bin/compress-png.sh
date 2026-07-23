#!/usr/bin/env bash
#
# compress-png: lossily compress PNG files in place with pngquant.
# Usage: compress-png.sh <file> [<file> ...]

set -euo pipefail

case ":$PATH:" in
  *:/opt/homebrew/bin:*) ;;
  *) PATH="/opt/homebrew/bin:$PATH" ;;
esac

for f in "$@"; do
  case "$f" in
    *.png | *.PNG) ;;
    *) continue ;;
  esac

  before=$(stat -f%z "$f")
  if pngquant --quality 65-90 --speed 1 --strip --skip-if-larger --force --ext .png -- "$f"; then
    after=$(stat -f%z "$f")
    msg="$(basename "$f"): $((before / 1024)) KB to $((after / 1024)) KB"
  else
    msg="$(basename "$f"): skipped, no smaller result"
  fi

  if [ -t 1 ]; then
    echo "$msg"
  else
    osascript -e "display notification \"$msg\" with title \"Compress PNG\"" >/dev/null
  fi
done
