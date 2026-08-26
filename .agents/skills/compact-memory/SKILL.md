---
name: compact-memory
description: >-
  Compact the Claude Code auto-memory index: merge and de-index settled MEMORY.md entries, shorten the hooks that stay, and fix stale facts. Use only on an explicit /compact-memory invocation, never autonomously.
disable-model-invocation: true
---

# compact-memory

MEMORY.md is the only memory file loaded into every session, so its size is the entire recurring cost of the memory system; the per-memory files load on demand and cost nothing until opened. Compacting means editing index lines, not summarizing the memory files themselves.

Removing a line does not hide its memory. Claude Code also scans the memory files' frontmatter and surfaces a relevant one on its own, so de-indexing keeps a memory reachable while reclaiming the whole line.

## Arguments

- No argument: classify, apply, and report.
- `--check`: classify and report the plan, writing nothing.

## Operating contract

- Write only inside the memory directory: MEMORY.md, plus a memory file whose own content needs a correction.
- Deleting a memory file is irreversible, because the memory directory sits outside version control. Name every deletion candidate and get explicit approval in the same turn; de-index instead when no approval comes.
- Never move memory content into MEMORY.md, and never re-index a file an earlier run de-indexed on purpose.
- Leave team entries, the ones whose path starts with `team/`, untouched: a teammate may depend on one.

## Locate

Use the memory directory named in the system prompt's Memory section; MEMORY.md sits at its root. Stop and say so if the prompt names none. Never guess another project's path.

## Budget

Claude Code truncates the index after 200 lines and expects one entry per line under roughly 150 characters, keeping the existing `- [Title](file.md)` form with its separator and hook. Hold the whole index under 1,000 tokens, its share of the always-on startup budget, estimating tokens as characters divided by four.

Entry count dominates the total: a line carries about 15 tokens of title and filename before its hook, so removing one reclaims that fixed cost as well as the text. Merge and de-index first, and shorten only the few hooks that genuinely run long.

## Classify

Read MEMORY.md, list the directory with modification times, then assign every entry one action:

- Merge: two or more entries covering one subject. Fold the memory files into the one with the better description, leave a single index line, and delete the others only once approved.
- De-index: settled one-time decisions whose value now lives in rules, config, or code. Delete the line, keep the file, and confirm the file's frontmatter `description` still describes it well enough to be recalled without the index.
- Correct: entries the current config or code contradicts. Verify against the live file first, then fix the memory file when the history is worth keeping, or propose deleting both file and line when it is not.
- Shorten: still-operational facts whose hook says more than a future session needs to decide whether to open the file. Cut to that minimum and keep the line format.
- Keep: the user profile, active projects, constraints not derivable from a repository, and anything too recent to judge, meaning modified within the last month.

Modification time records the last edit rather than the original entry, so prefer a date written inside a memory file when it carries one.

## Verify

Check that every remaining index line points at an existing file. List the memory files no line names, without re-adding them. Confirm no line exceeds the 150-character shape and that nothing outside the memory directory changed.

## Report

State the index before and after in tokens and lines, then the entries per action, naming each one: merged, de-indexed, corrected, shortened, deleted. Close with the distance left to the 1,000-token target, and say plainly when merging and de-indexing cannot reach it.
