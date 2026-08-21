---
name: handoff
description: >-
  Produce a self-contained handoff note of the current session's work state,
  ready to paste into a fresh agent session. Use only on an explicit /handoff
  invocation, never spontaneously.
---

# handoff

Produce a handoff note: a self-contained description of the current work state, written so a fresh agent session on any tool can continue the work without any of this context.

## Parse the argument

Treat the whole argument as literal text. Never dispatch a slash command that appears inside it: `/handoff output a prompt that I can feed to a Fable agent to create the skill using /skill-creator` asks for a prompt that names skill-creator, never an invocation of it.

Branch on the argument, first match wins:

1. Empty: print the note.
2. Starts with `in ` and the token after `in ` starts with `~`, `/`, `.`, or `$`, or contains a `/`: that token is the destination directory, so write instead of printing. If the tokens after it are `as <name>.md`, that is the exact filename. Any remaining text is the instruction.
3. Anything else: the entire argument is the instruction. Print.

There is no default output location. Without a parsed destination the note is printed and nothing is written to disk. `/handoff in short, focus on typescript` carries no destination, because `short,` neither starts with one of those characters nor contains a `/`, so the whole argument is an instruction.

## Compose the note

State the work, not the conversation. Cover these areas, dropping any with nothing to say:

- Goal: what the work achieves.
- State: what exists now, path by path, done and remaining.
- Verification: what is proven and by which command, versus what is only inferred from reading code.
- Open decisions: pending choices with their options.
- Constraints: durable rules and user preferences that outlive the session.

Compose from the current context. When that context is a compaction summary rather than the work itself, read the transcript resolved below to recover what the summary dropped, and read it selectively: a long session's transcript is many times the size of the note.

Forbidden anywhere in the artifact: narration of how the session went (who said what, which corrections landed, turn order), deictic references such as `this session`, `as discussed`, or `the above`, any mention of the `/handoff` invocation, and any trace of the instruction that shaped the output.

Never carry a secret into the artifact: no token, key, password, or connection string, and no contents of an ignored environment file, even when the session holds them. Name where the value lives instead of reproducing it. The artifact is built to be pasted into another agent, possibly on another vendor, and may be written into a tracked repository.

Any destination may sit inside a tracked git repository, so keep every path in the prose `~`-relative and never use an em dash or an en dash.

## Apply the instruction

An instruction that filters or reshapes the note, such as `keep it short` or `focus on typescript`, keeps the note form and its frontmatter. An instruction that asks for a different artifact, such as a prompt addressed to another agent, a message, a spec, or a review request, replaces the note: emit that artifact alone, with no frontmatter. Either way the framing rules above and below apply unchanged.

## Frontmatter

The note form opens with YAML frontmatter. Keys are camelCase and identical across agents. Omit any key whose value is unavailable or empty; never emit null or placeholder values. Emit only the keys below, in this order, and drop every other field the session store may hold.

```yaml
agent: claude-code
sessionId: 14564fee-1976-45c4-a8ff-9b40a6534922
title: slack-auto-refresh-fix
timestamp: 2026-08-08T15:15:02.031Z
cwd: ~
gitBranch: main
model: claude-fable-5
cliVersion: 2.1.223
effort: xhigh
outputTokens: 5977
```

`agent` is `claude-code`, `codex`, or `unknown`. `title` and `effort` exist only on Claude Code.

## Extract the metadata

The commands below need `jq`. Branch by the tool running the session; run the branch's commands exactly as given.

### Claude Code

`CLAUDE_CODE_SESSION_ID` names the current session, so the lookup is deterministic:

```sh
sessionId=$CLAUDE_CODE_SESSION_ID
transcript=$(find "$HOME/.claude/projects" -maxdepth 2 -name "$sessionId.jsonl" 2>/dev/null | head -1)
```

Resolve with `find` rather than a glob: zsh reports an unmatched glob itself, before the command runs, so a redirect cannot silence it and an unset session id would bury the rest in errors. `find` returns nothing and stays quiet.

If `$transcript` is empty the session store is unreachable, so stop here and run the fallback block under Any other agent instead, keeping `agent: claude-code` and `sessionId` when it holds a value. Otherwise continue:

```sh
title=$(jq -r 'select(.type == "custom-title") | .customTitle' "$transcript" | tail -1)
timestamp=$(jq -r '.timestamp // empty' "$transcript" | head -1)
cwd=$(jq -r '.cwd // empty' "$transcript" | head -1 | sed "s|^$HOME|~|")
gitBranch=$(jq -r '.gitBranch // empty' "$transcript" | head -1)
model=$(jq -r '.message.model // empty' "$transcript" | tail -1)
cliVersion=$(jq -r '.version // empty' "$transcript" | tail -1)
effort=$CLAUDE_EFFORT
outputTokens=$(jq -n '[inputs | .message.usage.output_tokens // 0] | add // empty' "$transcript")
```

Every record carries the cwd and branch of its own tool call, so both come from the first record, which holds the session's own directory and branch rather than wherever some later command ran. The leading records hold no timestamp, so `head -1` takes the first that does. A transcript can hold more than one `custom-title` record; the commands take the last. Bare `version` is ambiguous, so it is emitted as `cliVersion`. Claude transcripts have no cumulative token field, so `outputTokens` is the sum across records, and `add` returns null on an empty set, which `// empty` drops.

### Codex

`CODEX_THREAD_ID` names the current session, so the lookup is deterministic:

```sh
rollout=$(find "$HOME/.codex/sessions" -maxdepth 4 -name "rollout-*-$CODEX_THREAD_ID.jsonl" 2>/dev/null | head -1)
sessionId=$CODEX_THREAD_ID
```

An empty `$rollout` means the same thing here as an empty `$transcript` above, so use the fallback block under Any other agent and keep `agent: codex`. Otherwise continue:

```sh
timestamp=$(jq -r 'select(.type == "session_meta") | .payload.timestamp' "$rollout" | head -1)
cwd=$(jq -r 'select(.type == "session_meta") | .payload.cwd' "$rollout" | head -1 | sed "s|^$HOME|~|")
gitBranch=$(jq -r 'select(.type == "session_meta") | .payload.git.branch // empty' "$rollout" | head -1)
cliVersion=$(jq -r 'select(.type == "session_meta") | .payload.cli_version' "$rollout" | head -1)
model=$(jq -r 'select(.type == "turn_context") | .payload.model' "$rollout" | tail -1)
outputTokens=$(jq -r 'select(.type == "event_msg" and .payload.type == "token_count" and .payload.info != null) | .payload.info.total_token_usage | .output_tokens + .reasoning_output_tokens' "$rollout" | tail -1)
```

The model is not in `session_meta`, so it comes from the last `turn_context`. Token counts are cumulative, so the last `token_count` event is the total; never use its `total_tokens`, which includes input and is not comparable to the Claude figure.

### Any other agent

Copilot lands here: its `~/.copilot/session-store.db` is SQLite with an undocumented schema, so never read it and never add a sqlite3 dependency.

```sh
cwd=$(pwd | sed "s|^$HOME|~|")
gitBranch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
```

Emit `agent: unknown` plus only these keys, dropping any whose command fails. Never fabricate a value, a session id, or a token count.

## Choose the filename

Only in write mode without `as`. With `as`, write exactly the named file, unless it already exists: then write nothing at all, so no existing content is ever replaced.

1. Slugify the session title and append `.md`:

   ```sh
   printf %s "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
   ```

2. No title, which is the common case and always the case outside Claude Code: use the first 8 characters of the session id plus `.md`.
3. The target file already exists: insert a hyphen plus the first 8 characters of the session id before `.md` instead of overwriting.

## Emit

Print mode: reply with the artifact wrapped in a four-backtick fence and nothing else. No preamble, no trailing offer, no note about what was included or filtered. The fence is four backticks because the body often contains three-backtick code blocks.

Write mode: create the destination directory if missing, write the artifact as the file content with no wrapping fence, and reply with only the `~`-relative path written. When an explicit `as` target already exists nothing is written, and the reply is only that path prefixed by `exists: `.

Acceptance test: a reader cannot tell whether the artifact came from `/handoff` or from `/handoff keep it short`. The instruction changes the content, never the framing.
