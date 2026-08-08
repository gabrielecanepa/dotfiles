---
description: Show, validate and set statusline settings in .claude/statusline.json
argument-hint: '[key] [value]'
allowed-tools: Bash(sh:*)
disable-model-invocation: true
---

!`sh -c '
set -uf
case ":$PATH:" in *:/opt/homebrew/bin:*) ;; *) PATH="/opt/homebrew/bin:$PATH" ;; esac
config="${CLAUDE_STATUSLINE_CONFIG:-$HOME/.claude/statusline.json}"
schema_file="$HOME/.claude/statusline.schema.json"
bt=$(printf "\140")
if [ ! -r "$schema_file" ]; then
  printf "No statusline schema at %s, nothing to validate against.\n" "$schema_file"
  exit 0
fi
node="def node(\$k): getpath(\$k | split(\".\") | map([\"properties\", .]) | flatten);"
flat="if . == null then \"\" elif type == \"array\" then [.[] | if type == \"array\" then join(\" \") else tostring end] | join(\" / \") else tostring end"
csv() { printf "%s" "${1}" | sed "s/[^ ][^ ]*/$bt&$bt/g; s/ /, /g"; }
ask() { jq -r --arg k "${1}" --arg bt "$bt" "$node ${2}" "$schema_file" 2>/dev/null; }
values_of() {
  ask "${1}" "node(\$k) as \$n | (\$n.oneOf // \$n.items.items.oneOf) as \$o |
      if \$o then [\$o[].const] elif \$n.type == \"boolean\" then [\"true\", \"false\"] else [] end | join(\" \")"
}
options_of() {
  ask "${1}" "node(\$k) as \$n | (\$n.oneOf // \$n.items.items.oneOf) as \$o |
      if \$o then [\$o[] | \"- \" + \$bt + .const + \$bt + \": \" + (.description // \"\")] | join(\"\n\")
      elif \$n.type == \"boolean\" then \"- \" + \$bt + \"true\" + \$bt + \"\n- \" + \$bt + \"false\" + \$bt
      else \"\" end"
}
type_of() { ask "${1}" "node(\$k).type // \"\""; }
about_of() { ask "${1}" "node(\$k).description // \"\""; }
default_of() { ask "${1}" "node(\$k).default | $flat"; }
current_of() {
  printf "%s" "$base" | jq -r --arg k "${1}" "(try getpath(\$k | split(\".\")) catch null) | $flat" 2>/dev/null
}
effective_of() {
  _v=$(current_of "${1}")
  [ -n "$_v" ] || _v=$(default_of "${1}")
  printf "%s" "$_v"
}
keys=$(jq -r "def leaves(\$p): to_entries[] | select(.key != \"\$schema\") |
    (if \$p == \"\" then .key else \$p + \".\" + .key end) as \$k |
    if .value.type == \"object\" and (.value.properties | type) == \"object\" then (.value.properties | leaves(\$k)) else \$k end;
    [.properties | leaves(\"\")] | join(\" \")" "$schema_file" 2>/dev/null)
args="${1:-}"
key=${args%% *}
value=${args#"$key"}
value=${value# }
where=$(printf "%s" "$config" | sed "s|^$HOME|~|")
base="{}"
if [ -e "$config" ]; then
  base=$(jq "if type == \"object\" then . else empty end" "$config" 2>/dev/null)
  if [ -z "$base" ]; then
    printf "%s is not a readable JSON object, fix or delete it first.\n" "$where"
    exit 0
  fi
fi
if [ -z "$key" ]; then
  printf "Statusline config (%s):\n\n" "$where"
  for k in $keys; do
    listed=""
    [ "$(type_of "$k")" = "array" ] || listed=$(values_of "$k")
    if [ -n "$listed" ]; then
      printf -- "- %s%s%s: %s%s%s (%s)\n" "$bt" "$k" "$bt" "$bt" "$(effective_of "$k")" "$bt" "$(csv "$listed")"
    else
      printf -- "- %s%s%s: %s%s%s\n" "$bt" "$k" "$bt" "$bt" "$(effective_of "$k")" "$bt"
    fi
  done
  printf "\nSet one with %s/statusline-config <key> <value>%s.\n" "$bt" "$bt"
  exit 0
fi
case " $keys " in
  *" $key "*) ;;
  *)
    printf "Unknown key %s%s%s. Valid keys are: %s.\n" "$bt" "$key" "$bt" "$(csv "$keys")"
    exit 0
    ;;
esac
type=$(type_of "$key")
if [ -z "$value" ]; then
  if [ -n "$(current_of "$key")" ]; then
    printf "%s%s%s is %s%s%s (default %s%s%s).\n" "$bt" "$key" "$bt" "$bt" "$(effective_of "$key")" "$bt" "$bt" "$(default_of "$key")" "$bt"
  else
    printf "%s%s%s is %s%s%s, its default.\n" "$bt" "$key" "$bt" "$bt" "$(effective_of "$key")" "$bt"
  fi
  printf "%s\n" "$(about_of "$key")"
  listed=$(options_of "$key")
  [ -n "$listed" ] && printf "\n%s\n" "$listed"
  [ "$type" = "array" ] && printf "\nPass them space separated, %s/%s starts a new line.\n" "$bt" "$bt"
  exit 0
fi
if [ "$type" = "array" ]; then
  segments=$(values_of "$key")
  count=0
  for token in $value; do
    [ "$token" = "/" ] && continue
    case " $segments " in
      *" $token "*) count=$((count + 1)) ;;
      *)
        printf "Unknown segment %s%s%s. Valid segments are: %s.\n" "$bt" "$token" "$bt" "$(csv "$segments")"
        exit 0
        ;;
    esac
  done
  if [ "$count" -eq 0 ]; then
    printf "A layout needs at least one segment. Valid segments are: %s.\n" "$(csv "$segments")"
    exit 0
  fi
else
  valid=$(values_of "$key")
  if [ -n "$valid" ]; then
    case " $valid " in
      *" $value "*) ;;
      *)
        printf "Invalid %s%s%s value %s%s%s. Valid values are: %s.\n" "$bt" "$key" "$bt" "$bt" "$value" "$bt" "$(csv "$valid")"
        exit 0
        ;;
    esac
  fi
fi
seed="if has(\"\$schema\") then . else . + {\"\$schema\": \"./statusline.schema.json\"} end"
if [ "$type" = "array" ]; then
  set_to="(\$v | split(\"/\") | map(split(\" \") | map(select(length > 0))) | map(select(length > 0)))"
  out=$(printf "%s" "$base" | jq -S --arg k "$key" --arg v "$value" "$seed | setpath(\$k | split(\".\"); $set_to)" 2>/dev/null)
elif [ "$type" = "boolean" ]; then
  out=$(printf "%s" "$base" | jq -S --arg k "$key" --argjson v "$value" "$seed | setpath(\$k | split(\".\"); \$v)" 2>/dev/null)
else
  out=$(printf "%s" "$base" | jq -S --arg k "$key" --arg v "$value" "$seed | setpath(\$k | split(\".\"); \$v)" 2>/dev/null)
fi
if [ -z "$out" ]; then
  printf "Could not write %s.\n" "$where"
  exit 0
fi
if printf "%s\n" "$out" >"$config.tmp" && mv "$config.tmp" "$config"; then
  printf "Set %s%s%s to %s%s%s in %s.\n" "$bt" "$key" "$bt" "$bt" "$value" "$bt" "$where"
else
  rm -f "$config.tmp"
  printf "Could not write %s.\n" "$where"
fi
' -- "$ARGUMENTS"`

Output the block above verbatim as your entire reply, with nothing added before or after.
