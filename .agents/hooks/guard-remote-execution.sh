#!/bin/sh
#
# PreToolUse guardrail (Bash): block a command that executes a remote download
# without ever reading it. Two shapes are caught: a downloader piped into an
# interpreter (`curl url | sh`, `wget -qO- url | sudo bash`), and a download
# substituted into one (`bash <(curl url)`, `eval "$(curl url)"`). Downloading
# to a file, reading it, then running it explicitly is the supported path and
# always passes, as does any pipeline whose sink is not a shell.
#
# The scanner tokenizes the command, tracking quotes, substitutions, and
# grouping, so a downloader named inside an argument (`grep curl f | bash`) or
# separated by `;`, `&&`, or `||` does not trigger. Pipe sinks are shells,
# `eval`, and bare stdin-executing interpreters (python, node, perl, ruby,
# php); an interpreter handed a script path, `-c`, or `-m` is a normal
# pipeline sink, so `curl url | python3 -m json.tool` passes. Exit 2 blocks;
# a missing jq, an empty command, or any probe failure fails open.

set -u

case ":$PATH:" in
  *:/opt/homebrew/bin:*) ;;
  *) PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" ;;
esac

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0

reason="$(printf '%s' "$cmd" | awk '
function isdownloader(w) {
  return (w == "curl" || w == "wget" || w == "aria2c" || w == "http" || w == "httpie" || w == "fetch")
}
function isshell(w) {
  return (w == "sh" || w == "bash" || w == "zsh" || w == "dash" || w == "ksh" || w == "ash" ||
          w == "fish" || w == "csh" || w == "tcsh" || w == "eval" || w == "source" || w == ".")
}
function isinterp(w) {
  return (w ~ /^python[0-9.]*$/ || w == "node" || w == "nodejs" || w == "perl" ||
          w == "ruby" || w == "php")
}
function stdinexec(s,   a, m, i, w, seen) {
  seen = 0
  m = split(s, a, /[ \t\n]+/)
  for (i = 1; i <= m; i++) {
    w = a[i]
    if (w == "") continue
    if (!seen) {
      if (w ~ /^[A-Za-z_]/ && index(w, "=") > 0) continue
      sub(/^[^A-Za-z0-9_.\/-]+/, "", w)
      sub(/[^A-Za-z0-9_.\/-]+$/, "", w)
      if (w == "" || substr(w, 1, 1) == "-") continue
      sub(/^.*\//, "", w)
      if (iswrapper(w)) continue
      if (!isinterp(w)) return 0
      seen = 1
      continue
    }
    if (w == "-") return 1
    if (substr(w, 1, 1) != "-") return 0
  }
  return seen
}
function iswrapper(w) {
  return (w == "sudo" || w == "doas" || w == "env" || w == "command" || w == "exec" ||
          w == "nohup" || w == "time" || w == "nice" || w == "setsid" || w == "stdbuf" ||
          w == "builtin" || w == "xargs" || w == "then" || w == "else" || w == "elif" ||
          w == "do" || w == "done" || w == "fi" || w == "if" || w == "while" || w == "until" ||
          w == "for" || w == "in" || w == "!")
}
function cmdword(s,   a, m, i, w) {
  m = split(s, a, /[ \t\n]+/)
  for (i = 1; i <= m; i++) {
    w = a[i]
    if (w == "") continue
    if (w ~ /^[A-Za-z_]/ && index(w, "=") > 0) continue
    sub(/^[^A-Za-z0-9_.\/-]+/, "", w)
    sub(/[^A-Za-z0-9_.\/-]+$/, "", w)
    if (w == "" || substr(w, 1, 1) == "-") continue
    sub(/^.*\//, "", w)
    if (iswrapper(w)) continue
    return w
  }
  return ""
}
function opens(k) { ns++; seg[ns] = ""; sep[ns] = k; par[ns] = curpar }
BEGIN { DQ = sprintf("%c", 34); SQ = sprintf("%c", 39); BT = sprintf("%c", 96) }
{ if (NR > 1) all = all "\n"; all = all $0 }
END {
  n = length(all); ns = 0; seg[0] = ""; sep[0] = ""; par[0] = -1
  curpar = -1; dq = 0; sq = 0; bt = 0; pd = 0; i = 1
  while (i <= n) {
    c = substr(all, i, 1); d = substr(all, i + 1, 1)
    if (sq) { if (c == SQ) sq = 0; else seg[ns] = seg[ns] c; i++; continue }
    if (c == "\\") { seg[ns] = seg[ns] " "; i += 2; continue }
    if (c == SQ && !dq) { sq = 1; i++; continue }
    if (c == DQ) { dq = 1 - dq; i++; continue }
    if (c == "$" && d == "(") {
      pk[++pd] = "s"; pp[pd] = curpar; pq[pd] = dq
      curpar = ns; dq = 0; opens("$("); i += 2; continue
    }
    if (c == BT) {
      if (bt) { bt = 0; curpar = btpar; dq = btdq; opens(")") }
      else { bt = 1; btpar = curpar; btdq = dq; curpar = ns; dq = 0; opens("$(") }
      i++; continue
    }
    if (dq) { seg[ns] = seg[ns] c; i++; continue }
    if ((c == "<" || c == ">") && d == "(") {
      pk[++pd] = "s"; pp[pd] = curpar; pq[pd] = dq
      curpar = ns; opens("<("); i += 2; continue
    }
    if (c == "(") { pk[++pd] = "g"; pp[pd] = curpar; pq[pd] = dq; opens("("); i++; continue }
    if (c == ")") {
      if (pd > 0) { if (pk[pd] == "s") curpar = pp[pd]; dq = pq[pd]; pd-- }
      opens(")"); i++; continue
    }
    if (c == "|") { if (d == "|") { opens("||"); i += 2 } else { opens("|"); i++ } continue }
    if (c == "&") { if (d == "&") { opens("&&"); i += 2 } else { opens("&"); i++ } continue }
    if (c == ";" || c == "\n") { opens(";"); i++; continue }
    if (c == "{") {
      if (seg[ns] !~ /[^ \t\n]/ && (d == " " || d == "\t" || d == "\n")) { opens("{"); i++; continue }
      seg[ns] = seg[ns] c; i++; continue
    }
    if (c == "}") {
      if (seg[ns] !~ /[^ \t\n]/) { opens("{"); i++; continue }
      seg[ns] = seg[ns] c; i++; continue
    }
    seg[ns] = seg[ns] c; i++
  }

  for (k = 0; k <= ns; k++) cw[k] = cmdword(seg[k])

  for (k = 0; k <= ns; k++) {
    if (sep[k] != "|") continue
    if (!isshell(cw[k]) && !stdinexec(seg[k])) continue
    for (j = k - 1; j >= 0; j--) {
      if (isdownloader(cw[j])) {
        printf "a remote download is piped straight into %s", cw[k]; exit
      }
      if (sep[j] == "" || sep[j] == ";" || sep[j] == "&&" || sep[j] == "||" ||
          sep[j] == "&" || sep[j] == "{") break
    }
  }
  for (k = 0; k <= ns; k++) {
    if (!isdownloader(cw[k]) || par[k] < 0) continue
    if (isshell(cw[par[k]])) {
      printf "a remote download is substituted into %s", cw[par[k]]; exit
    }
  }
}
' 2>/dev/null)"

[ -n "$reason" ] || exit 0

printf 'Blocked by guard-remote-execution: %s. Download it to a file, read it, then run it explicitly.\n' "$reason" >&2
exit 2
