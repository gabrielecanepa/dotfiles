# Agentic architecture review

The rubric for reviewing how a repository's agentic files are designed and
organized. Use it in Phase 2 of sync-docs.

## Contents

- The `agents.md` standard in brief
- File taxonomy (what each file is for)
- Architecture checks (the judgment calls)
- Signal-density checks (what to cut)
- Constraint compliance

## The `agents.md` standard in brief

`AGENTS.md` is an open, plain-Markdown format — "a README for agents." It has no
required fields, no mandated sections, no frontmatter requirement; projects use
whatever headings carry the most signal. It is stewarded as an open standard and
read by most major coding agents, so treat it as the portable, tool-neutral
source of truth rather than tying instructions to one vendor's file.

Rules that matter for review:

- **Nearest wins.** In a monorepo or any nested layout, the `AGENTS.md` closest
  to the file being edited applies. So nested `AGENTS.md` files are legitimate
  and often correct — each subproject ships tailored instructions. Review them
  as a hierarchy: the root holds what's true everywhere; nested files hold only
  what differs.
- **Explicit prompts override files.** Documentation steers; it never overrides
  a direct instruction. Don't write docs that try to.
- **Listed checks get run.** If AGENTS.md names build/test/lint commands, agents
  will execute and try to pass them. So those commands must be correct and
  current — a stale command here is worse than none.
- **Complements the README, doesn't replace it.** README is for humans;
  AGENTS.md carries the agent-specific context that would clutter a README.

## File taxonomy

Map every agentic file to a role. A file with no clear role is a finding.

- **`AGENTS.md` (root)** — the source of truth. High-signal, project-specific
  context an agent can't infer from the repo itself: architecture, conventions,
  the spec-first workflow, non-obvious commands, hard constraints.
- **`AGENTS.md` (nested)** — only the deltas for a subproject. If a nested file
  largely repeats the root, that's redundancy to flag.
- **`CLAUDE.md` / tool entrypoints** — thin pointers to AGENTS.md, not parallel
  copies. The convention to enforce when the repo states it: `CLAUDE.md`
  contains only an `@AGENTS.md` include (or the tool's equivalent). Multiple
  fat, drifting entrypoints are the exact problem AGENTS.md exists to solve.
- **`.agents/**`\*\* — the canonical home for agentic assets (skills, commands,
  specs, guidelines). Check it's organized by kind, each asset is reachable and
  referenced, and nothing is orphaned.
- **Skills** — each `SKILL.md` should have a crisp description (the trigger),
  stay lean in the body, and push detail to references. Check skills are
  well-formed and that their descriptions actually trigger on the intended use.
- **`.claude/**`\*\* — settings, commands, subagents. Check it's consistent with
  AGENTS.md and not duplicating it.

## Architecture checks

The judgment calls. For each, the question is whether the _current_ arrangement
is the best one for an agent to work with.

- **Source-of-truth integrity.** Is AGENTS.md genuinely authoritative? Do
  entrypoints point to it rather than fork it? Any contradictions between files?
- **Does each file earn its place?** Purpose, audience, and unique content. A
  file that duplicates another, or that no one reads, or that a tool config
  already covers, is a candidate for merge or deletion.
- **Grouping and splitting.** Is related guidance together and unrelated
  guidance apart? Is anything so long it should split (progressive disclosure —
  lean entry file, detail in references)? Is anything so fragmented it should
  merge? In monorepos, is the root/nested division clean?
- **Progressive disclosure.** The entry files (AGENTS.md, each SKILL.md) should
  be scannable; depth belongs in referenced files loaded on demand. Flag entry
  files that try to hold everything.
- **Tool fit.** Are the right mechanisms used for each job — a skill where a
  skill belongs, a command where a command belongs, AGENTS.md prose only for
  what can't be a tool or skill? Are they used correctly (valid frontmatter,
  working includes, correct paths)?
- **Coverage.** Is anything an agent needs missing — setup, non-obvious build
  steps, conventions, gotchas, the workflow the repo follows? Gaps are as much a
  finding as bloat.

## Signal-density checks (what to cut)

Bloated and generically-written context files measurably reduce agent success
and raise cost. Bias toward cutting:

- **Toolchain duplication.** If a linter, formatter, type checker, or CI config
  already enforces a rule, AGENTS.md should not restate it — it should point to
  the tool. Describe only behavioral rules no tool can express.
- **Generic advice.** "Write clean code," "follow best practices," restated
  language docs — zero signal. Cut or replace with the specific, local rule.
- **Obvious-from-the-repo content.** The stack and structure that an agent can
  read off `package.json` and the directory tree don't need narrating unless
  there's a non-obvious twist.
- **Stale scaffolding.** Placeholder sections, TODOs that never resolved,
  instructions for tools no longer used.

The test for keeping a line: would an agent do worse without it? If not, cut it.

## Constraint compliance

Whatever the docs declare is the standard to check against. Constraints are
stated in no fixed format — infer them from the text and honor them as written:

- **Token / length budgets** — measure with `scripts/count_tokens.py --budget N`.
  Flag files over budget and propose a split or trim rather than silently
  blowing past it.
- **Structure / naming conventions** — section order, file naming, folder
  layout the repo prescribes.
- **Voice and vocabulary rules** — tone, banned words, formatting conventions.
- **Project-specific conventions** — e.g. a thin-CLAUDE.md rule, a single-source
  rule, a spec-first workflow. Check files conform.

Report compliance as concrete pass/fail items so the proposal can show exactly
what's off and what fixing it costs.
