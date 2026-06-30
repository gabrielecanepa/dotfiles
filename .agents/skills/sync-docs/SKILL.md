---
name: sync-docs
description: >-
  Audit and update all documentation in the current scope: agentic files
  (AGENTS.md, CLAUDE.md, .agents/, skills, tool entrypoints) and human-facing
  docs (README, CONTRIBUTING, docs/). Reviews the architecture of the agentic
  setup, validates files against any constraints AGENTS.md declares, and brings
  every doc up to date, concise, and exhaustive. It applies the clear-cut fixes
  itself and stops to ask — with selectable options — only when a real decision
  is the user's to make, then reports what changed. Use this whenever the user
  runs `/docs`
  (with or without a prompt), or whenever they mention updating, reviewing,
  syncing, auditing, or cleaning up documentation, README files, AGENTS.md,
  CLAUDE.md, agent instructions, or the .agents/ setup — even if they don't say
  "sync-docs". Inside a project it operates only on that project's docs; run
  from outside a project it operates on the home (~) docs.
---

# sync-docs

Keep a repository's documentation honest: current, concise, exhaustive, and
well-architected for the agents and humans who read it. This skill scans every
in-scope document, reviews how the agentic setup is organized, finds drift and
dead weight, fixes what's unambiguous, and stops to ask only when a real
decision is the user's to make.

The bar to hold: an agent dropped cold into this repo should find everything it
needs to work well, and nothing it doesn't. A human contributor should find a
README that serves them and not a wall of agent instructions.

## Operating contract

Hold these for the whole run — they are what makes the skill safe to invoke
broadly:

- **Act on the clear wins; ask only for real decisions.** Apply every fix that
  has a single best answer — drift, obvious compliance fixes, removing dead
  duplicates. Stop only where a genuine choice is the user's to make, and put it
  to them as selectable options. Don't ask about the obvious; don't unilaterally
  settle the genuinely ambiguous.
- **Stay inside the resolved scope.** Read and write only within the root
  resolved in Phase 0. Never cross between a project and the home directory.
- **AGENTS.md is the source of truth.** Everything else either points to it
  (entrypoints like CLAUDE.md) or complements it (README for humans). Resolve
  contradictions in its favor unless the content is plainly stale.
- **Honor declared constraints; don't invent them.** Whatever rules the docs
  state — token budgets, length caps, structure, naming, banned vocabulary —
  are the law. Infer them from the text; apply them; flag violations. Do not
  impose preferences the repo never asked for.
- **Bias to signal density.** More words is not better. Context files that
  restate what tool configs already enforce, or pad with generic advice,
  measurably _lower_ agent success. Cut anything that doesn't earn its place.
- **Anchor to the standard.** Align to the `agents.md` open format and proven
  patterns. When current practice might have moved, research it (Phase 2)
  rather than guessing.
- **Write like a human.** When a `humanizer` skill is available, route the
  written output — the decision questions and the final recap — through it so
  the prose reads naturally instead of mechanical. If it isn't available, write
  plainly and directly yourself.
- **Removals must be recoverable.** Auto-remove a file only when it's
  git-tracked, using `git rm` so it stays recoverable. For untracked files or
  non-git (home) scope, treat removal as a decision and ask first, or back the
  file up to a timestamped location before removing — never a silent hard
  delete.

## The optional prompt

`/docs <prompt>` may carry an instruction. Read it as intent and fold it into
scope and priority — e.g. "the README is stale after the auth refactor" narrows
the sweep to drift in one area; "tighten the skills folder" focuses the
architecture review. Always still do a baseline pass over the rest so nothing
silently rots, but lead with what the prompt asked for. No prompt → full sweep.

## Phase 0 — Resolve scope

Decide which root you operate on, and say so before doing anything else.
Surprise about _which_ files you touched is the worst outcome here.

1. Get the current directory.
2. Find a project root: run `git rev-parse --show-toplevel` from cwd. If it
   returns a path that is **not** the home directory, that path is the project
   root → **project scope**.
3. No git? Walk up from cwd looking for a project marker (`AGENTS.md`,
   `.agents/`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`),
   stopping **before** `~`. First marker found → project root.
4. If cwd is the home directory itself, or no project root is found above `~`,
   use **home scope** with root `~`.

State the resolved scope and root in one line, then proceed. If the cwd is
ambiguous (e.g. a bare clone living directly under `~`), name the ambiguity and
confirm before scanning.

## Phase 1 — Inventory

Build a manifest of every in-scope document. Read `references/agentic-architecture.md`
for the full file taxonomy; the short version:

**Agentic files**

- `AGENTS.md` at the root **and** any nested `AGENTS.md` in subdirectories —
  each is its own surface (nearest-wins), so review them as a set, not one file.
- `CLAUDE.md` and other tool entrypoints (`.cursor/rules/*`, `.cursorrules`,
  `.github/copilot-instructions.md`, `GEMINI.md`, `.windsurfrules`,
  `.clinerules`, `.aider*`).
- `.agents/**` — the canonical agentic folder (skills, commands, specs).
- `.claude/**` — settings, commands, agents, skills if present.

**Human-facing docs**

- `README.md`, `CONTRIBUTING.md`, `docs/**`, `ARCHITECTURE.md`, `SECURITY.md`,
  and similar. Treat generated files (e.g. a `CHANGELOG.md` produced by
  release-it) as generated — review for config drift, don't hand-edit.

For each file record: path, role, and a token estimate via
`python scripts/count_tokens.py <files>` (run it from the skill directory; add
`--budget N` once you know a declared budget). Note the tokenizer is an estimate.

Then extract **declared constraints**: read AGENTS.md and any `.agents/` config
for stated rules (budgets, caps, structure, naming, voice, the thin-entrypoint
convention). Record each as a checkable item for Phase 2.

## Phase 2 — Analyze

Run the review against two rubrics. Load them now:

- **Agentic architecture** → `references/agentic-architecture.md`. Covers source-
  of-truth integrity, the file taxonomy, progressive disclosure, redundancy and
  dead files, grouping/splitting, tool fit, and the signal-density checks.
- **Human docs quality** → `references/human-docs.md`. Covers the README/agent
  separation, currency, and the concise-yet-complete bar.

Across both, judge every file on four axes:

1. **Current** — does it match the actual code, stack, scripts, and structure?
   Verify claims against the repo (package scripts, configs, exports, directory
   layout), don't trust the prose. Drift is the most common and most damaging
   failure.
2. **Concise** — no padding, no duplication of what tools already enforce, no
   generic filler. Shorter when it loses nothing.
3. **Exhaustive** — nothing an agent or contributor genuinely needs is missing.
   Conciseness never wins by omitting load-bearing context.
4. **Compliant** — passes every constraint the docs declared.

**Research when it helps.** If the setup could benefit from a newer pattern,
tool, or convention — or if the `agents.md` standard may have moved — search for
current practice and fold proven approaches into the proposal. Keep suggestions
anchored to established standards; flag anything experimental as such.

Produce a findings list: each item is a concrete problem with its location and
why it matters. This is the raw material for the proposal — don't show the user
a stream of consciousness, synthesize it.

## Phase 3 — Resolve and apply

Work through the findings. For each, make one call: is there a single best
answer, or is this the user's to decide?

**Apply automatically** when the fix is unambiguous and low-risk — make the edit
directly, matching the repo's existing voice and conventions:

- factual drift (wrong command, dead link, renamed script, stale path),
- compliance fixes with one obvious resolution (relocate misplaced content into
  AGENTS.md, reduce an entrypoint to a thin pointer, split an over-budget file),
- removing a git-tracked file that is dead or a zero-delta duplicate — via
  `git rm`, so it stays recoverable,
- cutting clear bloat or toolchain-duplicated content.

Don't narrate each edit as you go; you'll account for them all in the recap.

**Stop and ask** — as selectable options — when the call is genuinely the
user's:

- two or more reasonable solutions with real tradeoffs (consolidate vs. keep
  split; which of several near-duplicates becomes canonical),
- editorial latitude on human-facing prose (a factual fix is automatic; a
  structural rewrite is the user's choice),
- intent you can't verify (a zero-delta nested file someone may have meant to
  fill in; content that might be load-bearing),
- any removal that wouldn't be git-recoverable (untracked file, or home scope).

Pose each as a plain question with concrete options and a recommended default,
using the host's question/options mechanism so it renders as selectable choices.
Keep resolving everything else while a decision waits — only block when applying
the rest genuinely depends on the answer.

After editing, if AGENTS.md lists programmatic checks (lint, test, typecheck,
build), run the relevant ones and fix failures your changes caused — the
standard expects an agent to leave the repo green. Never commit or push
automatically; offer a Conventional Commit and leave the boundary to the user.

## Phase 4 — Recap

Close with a concise record (run it through `humanizer` if available so it
doesn't read like a changelog robot):

- **Changed** — what you applied, one line each with the why.
- **Decisions pending** _(if any)_ — the questions you raised and their options,
  so an unanswered one stays visible rather than lost.
- **Manual follow-ups** _(if any)_ — anything only the user can do: verify a
  staging URL you couldn't reach, fill in a nested AGENTS.md they chose to keep,
  run a check outside your reach.

Keep it scannable. If everything was unambiguous, the recap is just the change
list — no ceremony.

## Bundled resources

- `scripts/count_tokens.py` — token estimate per file, with `--budget` and
  `--json`. tiktoken if available, else a chars/4 estimate.
- `references/agentic-architecture.md` — the agentic-file review rubric and the
  `agents.md` standard in brief.
- `references/human-docs.md` — the human-facing docs quality bar.
