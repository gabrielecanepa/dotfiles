---
name: fleet
description: >-
  Hand the current session to the Mac agent view: start a named background copy
  with claude --bg --resume and tell the user where to continue. Use for
  /fleet [name], mainly from a phone session.
disable-model-invocation: true
argument-hint: '[name]'
---

# fleet

Start a background copy of this session so it appears in `claude agents` on the Mac, then hand over to it.

A running session cannot be moved; `claude --bg --resume` on a live session starts a copy under a new id and says so. The copy resumes from the last saved turn.

## Resolve the inputs

```sh
sessionId=$CLAUDE_CODE_SESSION_ID
```

An empty `sessionId` means the session store is unreachable: stop and say so.

The name is the whole argument. Without one, reuse the display name this session already has:

```sh
name=$(find "$HOME/.claude/sessions" -maxdepth 1 -name '*.json' -exec jq -r --arg id "$sessionId" 'select(.sessionId == $id) | .name // empty' {} + 2>/dev/null | head -1)
```

Without either, omit `--name` and let the copy name itself.

## Start the copy

Run from the current working directory, which the copy inherits:

```sh
claude --bg --resume "$sessionId" --name "$name"
```

Drop `--name "$name"` when `name` is empty.

The command prints the short id of the copy and, when this session is still running, a line saying a copy was started. Keep both lines.

When the command fails, print its output and stop; never retry with `--fork-session` or a different id.

## Reply

Reply with these lines and nothing else:

1. The short id and `claude attach <id>` for the Mac.
2. That this session is the original and stays open: continue in the copy, from agent view on the Mac or from its entry in the phone's Code tab, and send nothing more here, because later turns here never reach the copy.
3. The name the copy carries.
