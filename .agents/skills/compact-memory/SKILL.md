---
name: compact-memory
description: >-
  Compact the Claude Code auto-memory index: merge and de-index settled MEMORY.md entries, shorten hooks, fix stale facts.
  Use only on an explicit /compact-memory invocation.
disable-model-invocation: true
---

# compact-memory

MEMORY.md is the only memory file loaded into every session, so its size is the whole recurring cost of memory.

- Compacting edits index lines, never the memory files' content.
- De-indexing hides nothing: Claude Code also scans memory file frontmatter and surfaces a relevant file on its own.

## Arguments

- No argument: classify, apply, and report.
- `--check`: classify and report the plan, writing nothing.

## Operating contract

- Write only inside the memory directory: MEMORY.md, plus a memory file whose own content needs a correction.
- When a memory file is a deletion candidate, name it and get explicit approval in the same turn; deletion is irreversible because the directory is untracked.
- When no approval comes, de-index instead of deleting.
- Never move memory content into MEMORY.md.
- Never re-index a file an earlier run de-indexed on purpose.
- Leave entries whose path starts with `team/` untouched; a teammate may depend on one.

## Locate

- Use the memory directory named in the system prompt's Memory section; MEMORY.md sits at its root.
- When the prompt names no directory, stop and say so; never guess another project's path.

## Budget

- Hold the index at 500 tokens or fewer, estimating tokens as characters divided by four; 800 is the hard cap.
- Keep one entry per line in the existing `- [Title](file.md) <separator> <hook>` form, under 150 characters; Claude Code truncates the index after 200 lines.
- Merge and de-index first, because a line costs about 15 tokens before its hook; shorten only the hooks that genuinely run long.

## Classify

Read MEMORY.md, list the directory with modification times, then assign every entry one action:

- Merge: two or more entries cover one subject. Fold the files into the best-described one, keep one index line, and delete the others only once approved.
- De-index: a settled decision whose value now lives in rules, config, or code. Delete the line, keep the file, and check its `description` still fits.
- Correct: the current config or code contradicts the entry. Verify against the live file, then fix the memory file, or propose deleting file and line together.
- Shorten: a still-operational fact whose hook says more than a session needs to decide whether to open the file. Cut to that minimum and keep the line format.
- Keep: the user profile, active projects, constraints not derivable from a repository, and anything modified within the last month.
- When a memory file carries a date inside, prefer it over the modification time, which records only the last edit.

## Verify

- Check that every remaining index line points at an existing file.
- List the memory files no line names, without re-adding them.
- Confirm no line exceeds 150 characters and nothing outside the memory directory changed.

## Report

- State the index before and after in tokens and lines.
- List the entries per action by name: merged, de-indexed, corrected, shortened, deleted.
- Close with the distance left to the 500-token target, and say plainly when merging and de-indexing cannot reach it.
