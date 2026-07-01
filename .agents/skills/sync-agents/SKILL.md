---
name: sync-agents
description: >-
  Audits and repairs a repository's agentic documentation: AGENTS.md and every
  nested AGENTS.md, tool entrypoints (CLAUDE.md, .cursor/rules, GEMINI.md,
  copilot-instructions), the .agents/ and .claude/ trees, skills, and rule
  files. Checks architecture and constraint compliance, then fixes drift, bloat,
  and dead weight, applying clear-cut fixes and asking only for real decisions.
  Use
  whenever the user runs `/sync-agents`, or mentions auditing, syncing,
  reviewing, tightening, or cleaning up AGENTS.md, CLAUDE.md, agent
  instructions, the .agents/ or .claude/ setup, skills, or rule files, even if
  they don't say "sync-agents". Does not touch human docs (README, CONTRIBUTING,
  docs/). Scopes to a path when one is given, else the whole agentic surface;
  `--check` audits without editing.
---

# sync-agents

Keep a repository's **agentic documentation** honest: current, dense, well
architected for the agents that read it. This skill scans every agentic file in
scope, reviews how the setup is organized, finds drift and dead weight, fixes
what's unambiguous, and stops to ask only when a real decision is the user's.

Human-facing docs (README, CONTRIBUTING, `docs/`) are explicitly out of scope.
Do not read them for editing, do not touch them. The one exception is the
README-vs-AGENTS.md boundary check in Phase 2, which is an agentic-architecture
concern, not a human-doc edit.

## Arguments

The invocation may carry two things, both optional. Parse them from the prompt
before Phase 0.

- **A scope path or area** (e.g. `/sync-agents the skills folder`,
  `/sync-agents .agents/rules`). Present → narrow the sweep to that subtree and
  lead there, but still do a light baseline pass over the rest of the agentic
  surface so nothing silently rots. Absent → audit **all** agentic docs in the
  resolved root.
- **`--check`** → audit only. Produce the findings and the recap, apply **no**
  edits and remove nothing. This is the read-only inversion of the default.

## Operating contract

Hold these for the whole run.

- **Act on the clear wins; ask only for real decisions.** Apply every fix with a
  single best answer: drift, obvious compliance fixes, removing dead
  duplicates. Stop only where a genuine choice is the user's, and put it as
  selectable options. Don't ask about the obvious; don't unilaterally settle the
  genuinely ambiguous. Under `--check`, apply nothing: report both the clear
  fixes you would make and the decisions you'd raise.
- **Stay inside the resolved scope.** Read and write only within the root
  resolved in Phase 0 (and within the scope path if one was given). Never cross
  between a project and the home directory.
- **AGENTS.md is the source of truth when it exists.** Everything else either
  points to it (entrypoints like CLAUDE.md) or is subordinate to it; resolve
  contradictions in its favor unless the content is plainly stale. If no
  AGENTS.md exists in scope, don't invent one or point files at it: audit the
  entrypoints and rules that do exist on their own terms, and treat consolidating
  them into a new AGENTS.md as a decision to ask, never an auto-fix.
- **Honor declared constraints; don't invent them.** Whatever the docs state,
  token budgets, length caps, structure, naming, banned vocabulary, is the law.
  Infer it from the text, apply it, flag violations. Do not impose preferences
  the repo never asked for.
- **Bias to signal density.** More words is not better. Context files that
  restate what tool configs already enforce, or pad with generic advice,
  measurably _lower_ agent success and cost tokens every session. Cut anything
  that doesn't earn its place.
- **Anchor to the standard.** Align to the `agents.md` open format (an open
  standard under the Linux Foundation's Agentic AI Foundation) and proven
  patterns. When current practice might have moved, research it (Phase 2) rather
  than guessing.
- **Write the human-facing output plainly.** The decision questions and the
  final recap are read by a person: lead with the answer, cut filler, no dashes.
  Route them through a `humanizer` skill if one is available, but don't depend on
  it.
- **Removals must be recoverable.** Auto-remove a file only when it's
  git-tracked, using `git rm` so it stays recoverable. For untracked files or a
  non-git (home) scope, treat removal as a decision and ask first, or back the
  file up to a timestamped location before removing. Never a silent hard delete.

## Phase 0: resolve scope

Decide which root you operate on, and say so before touching anything.

1. Get the current directory.
2. Find a project root: run `git rev-parse --show-toplevel` from cwd. If it
   returns a path that is **not** the home directory, that path is the project
   root → **project scope**.
3. No git? Walk up from cwd for a project marker (`AGENTS.md`, `.agents/`,
   `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`), stopping
   **before**
   `~`. First marker found → project root.
4. If cwd is the home directory itself, or no project root is found above `~`,
   use **home scope** with root `~`.

State the resolved scope and root in one line. If a scope path was given, state
it too. Then proceed. If cwd is ambiguous (e.g. a bare clone directly under
`~`), name the ambiguity and confirm before scanning.

## Phase 1: inventory

Build a manifest of every in-scope agentic file. Read
[references/agentic-architecture.md](references/agentic-architecture.md) for the
full taxonomy; the short version:

- **`AGENTS.md`** at the root **and** every nested `AGENTS.md` in subdirectories.
  Exclude two look-alikes that a bare `find` surfaces but that aren't nested
  deltas: any `AGENTS.md` under a registered git worktree (run `git worktree
list` and skip those roots; a worktree's file is a branch copy, and diffing it
  against root manufactures phantom findings) and any under a vendored skill
  body (`skills/<name>/`), which ships with third-party assets you don't audit.
- **Tool entrypoints**: `CLAUDE.md`, `.cursor/rules/*`, `.cursorrules`,
  `.github/copilot-instructions.md`, `.github/instructions/*`, `GEMINI.md`,
  `.windsurfrules`, `.clinerules`, `.aider*`.
- **MCP server config**: `.mcp.json`, plus tool variants (`.cursor/mcp.json`,
  `.vscode/mcp.json`, and the `mcpServers` block in `.claude/settings.json`).
- **`.agents/**`\*\*: the canonical agentic folder (rules, skills, commands,
  hooks, output styles, specs).
- **`.claude/**`\*\*: settings, commands, subagents, skills if present.

For each file record: path and role. Count size only when AGENTS.md or an
`.agents/` config declares a token budget or line cap, via
`python scripts/count_tokens.py <manifest-paths>` (run from the skill directory,
passing the in-scope files as arguments, never a directory). The script reports
both tokens and lines; the tokenizer is an estimate. Match the check to what the
repo declared: for a token budget, pass `--budget N`; for a line cap (just as
common), read the `LINES` column, since `--budget` only guards tokens.

Then extract **declared constraints**: read AGENTS.md and any `.agents/` config
for stated rules (budgets, caps, structure, naming, voice, the thin-entrypoint
convention, single-source rules). Record each as a checkable item for Phase 2.

## Phase 2: analyze

Load the rubric now: **[references/agentic-architecture.md](references/agentic-architecture.md)**.
It covers the `agents.md` standard, the file taxonomy, source-of-truth
integrity, progressive disclosure, redundancy and dead files,
grouping/splitting, tool fit, the signal-density checks, and constraint
compliance. Judge every file on four axes:

1. **Current**: does it match the actual code, stack, scripts, and structure?
   Verify claims against the repo (package scripts, configs, exports, directory
   layout, symlink targets), don't trust the prose. Drift is the most common and
   most damaging failure. A stale build/test/lint command in AGENTS.md is worse
   than none, because agents execute listed checks.
2. **Concise**: no padding, no duplication of what tools already enforce, no
   generic filler. Shorter when it loses nothing.
3. **Exhaustive**: nothing an agent genuinely needs is missing. Conciseness
   never wins by dropping load-bearing context (setup, non-obvious commands,
   conventions, gotchas, the workflow the repo follows).
4. **Compliant**: passes every constraint the docs declared.

One boundary check that spans into human docs but is an architecture concern:
**does the README carry heavy agent-only instruction, or is agent context
buried where humans land?** If so, flag it (move the agent content into
AGENTS.md) as a finding. This is the only reason to open the README, and even
then you propose the move, you don't rewrite the README's prose.

**Research only on a real knowledge gap.** When a finding depends on an external
fact you can't confirm from the repo (a tool's current config format, or whether
the `agents.md` standard changed a rule you're about to enforce or propose),
search current practice and fold proven approaches into the proposal. Don't
open-endedly scan for newer patterns on a healthy sync. Keep suggestions anchored
to established standards; flag anything experimental as such.

Produce a synthesized findings list: each item is a concrete problem with its
location and why it matters. Don't show a stream of consciousness.

## Phase 3: apply (default) or report (`--check`)

Work through the findings. For each, make one call: single best answer, or the
user's to decide?

Under **`--check`**, apply nothing. List what you would auto-apply and what
you'd raise as a decision, then jump to Phase 4. Everything below describes the
default (apply) path.

**Apply automatically** when the fix is unambiguous and low-risk. Make the edit
directly, matching the repo's existing voice and conventions:

- factual drift (wrong command, dead link, renamed script, stale path or
  symlink target),
- compliance fixes with one obvious resolution (relocate misplaced content into
  AGENTS.md, reduce a fat entrypoint to a thin pointer, split an over-budget
  file). One caveat on thinning entrypoints: only tools whose format supports an
  include can point (CLAUDE.md's `@AGENTS.md`, Cursor's MDC). Copilot's
  `.github/copilot-instructions.md` has no include, so never convert it to a fake
  `@` pointer Copilot would render as literal text,
- removing a git-tracked file that is dead or a zero-delta duplicate, via
  `git rm`, so it stays recoverable,
- cutting clear bloat or toolchain-duplicated content,
- rewriting a weak or non-triggering skill description when the skill's purpose
  is clear from its name and body: that's a low-risk repair, not a decision.
  Only when the whole skill is a content-less stub (no real body) does fix vs.
  remove become the user's call.

Don't narrate each edit as you go; account for them all in the recap.

**Stop and ask**, as selectable options, when the call is genuinely the user's:

- two or more reasonable solutions with real tradeoffs (consolidate vs. keep
  split; which near-duplicate becomes canonical),
- intent you can't verify (a zero-delta nested file someone may mean to fill in;
  content that might be load-bearing),
- a `.github/copilot-instructions.md` that duplicates AGENTS.md. Copilot loads
  both together (AGENTS.md primary, copilot-instructions additional), so a
  duplicate is not automatically dead weight: flag the overlap and ask whether to
  remove it, recommending removal only when it adds nothing Copilot-specific.
  Never auto-`git rm` it,
- any removal that wouldn't be git-recoverable (untracked file, or home scope).

Pose each as a plain question with concrete options and a recommended default,
using the host's question mechanism. Keep
resolving everything else while a decision waits; only block when applying the
rest genuinely depends on the answer.

After editing, if AGENTS.md lists programmatic checks (lint, test, typecheck,
build) that your changes could affect, run the relevant ones and fix failures
your changes caused. Never commit or push automatically; the commit boundary is
the user's.

## Phase 4: recap

Close with a scannable record. Lead with a one-line verdict, then:

- **Scope**: the resolved root, the scope path if any, and mode (applied /
  `--check` audit).
- **Changed**: what you applied, one line each with the why. Under `--check`,
  retitle this **Would change** and list the fixes you'd make instead.
- **Decisions pending** _(if any)_: the questions you raised and their options,
  so an unanswered one stays visible.
- **Follow-ups** _(if any)_: anything only the user can do (fill in a nested
  AGENTS.md they chose to keep, run a check outside your reach, a README move you
  flagged).

If everything was unambiguous and applied, the recap is just the verdict and the
change list. No ceremony. When work is commit-worthy, offer a Conventional
Commit message and leave the commit to the user.

## Bundled resources

- [references/agentic-architecture.md](references/agentic-architecture.md): the
  agentic-file review rubric and the `agents.md` standard in brief. Loaded in
  Phase 2.
- `scripts/count_tokens.py`: per-file token estimate, with `--budget` and
  `--json`. tiktoken if available, else a chars/4 estimate.
