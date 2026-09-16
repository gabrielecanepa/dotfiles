---
name: sync-docs
description: Audit and repair human-facing repository docs against the code. Use for /sync-docs or to review README, CONTRIBUTING, CHANGELOG, or guides; excludes agentic files, supports --check.
---

# sync-docs

Audit every human-facing doc in scope, check each claim against the repo, fix what has one answer, and ask only where the call is editorial.

- Out of scope: `AGENTS.md` and nested copies, `CLAUDE.md` and other tool entrypoints, the `.agents/` and `.claude/` trees.
- Also out of scope: rule files, any `SKILL.md`, and MCP config; the `sync-agents` skill owns that surface.
- The only crossing is the Phase 2 README boundary check, which proposes a move and never edits an agentic file.

## Arguments

Parse both arguments from the prompt before Phase 0.

1. When the prompt names a scope path or area, lead there and still run a light baseline pass over the remaining human docs.
2. When no path is given, audit every human doc under the resolved root.
3. When `--check` is present, audit only: apply no edit and remove no file.

## Operating contract

- When a finding has a single best answer, apply it without asking: a wrong command, a dead link, a stale path, a removed feature, a banned dash.
- When a finding is genuinely editorial, stop and ask with concrete options and a recommended default, using the host's question mechanism.
- When prose and repo disagree, treat the repo as the source of truth and fix the doc.
- When the code looks wrong and the doc looks right, flag it as a follow-up and never change code from a docs sync.
- When the repo declares a doc style, apply that style as law; otherwise match the surrounding document's own voice.
- When cutting for signal, keep every load-bearing step, gotcha, and concrete detail; a voice edit is not a compression pass.
- When editing prose, treat AI-writing tells as defects on the same footing as a dead link, and never write an em or en dash.
- When removing a doc, use `git rm` for a tracked file; for an untracked file or a non-git scope, ask first or back it up to a timestamped location.

## Phase 0: resolve scope

1. Get the current directory.
2. Run `git rev-parse --show-toplevel`; when it returns a path other than the home directory, that path is the project root and the scope is project.
3. When there is no git root, walk up from cwd stopping before `~`, and take the first root marker found as the root.
4. Root markers: `README.md`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `docs/`.
5. When cwd is the home directory itself, or no root is found above `~`, stop and ask instead of scanning.
6. State the resolved scope, the root, the scope path if one was given, and the mode in one line, then proceed.
7. When cwd is ambiguous, name the ambiguity and confirm before scanning.

## Phase 1: inventory

1. Read [references/doc-inventory.md](references/doc-inventory.md), then build a manifest of every in-scope human doc with its path and role.
2. Inventory `.github/` as well as the repo root, and treat the copy GitHub would render as the canonical one.
3. Never read for editing, or touch, anything the reference lists as out of scope.
4. When the repo declares a doc length or line-width cap, measure against it with a counter rather than eyeballing.
5. Extract declared conventions from `CONTRIBUTING`, a `STYLE` or `STYLEGUIDE` file, and the existing docs' own patterns.
6. Read any `.markdownlint*`, `.vale.ini`, `.textlintrc`, `.remarkrc`, or `cspell` config for the mechanical rules.
7. Record each convention as a checkable item for Phase 2, and prefer running the linter over hand-checking what it covers.

## Phase 2: analyze

1. Load [references/prose-review.md](references/prose-review.md) before judging any doc.
2. Judge every doc on four axes: current, coherent, complete, and clean in voice.
3. Verify currency claim by claim against the repo, exactly as the reference's currency checks spell out; this axis is load-bearing.
4. When the README carries heavy agent-only instruction, flag it and propose moving it into the agentic surface as a `sync-agents` follow-up.
5. When the `humanizer` skill is installed (source `blader/humanizer`), route substantive prose through its draft, audit, and final loop.
6. When `humanizer` is absent, apply the reference's writing-voice baseline inline instead of blocking on the skill.
7. When a finding depends on an external fact the repo cannot settle, verify that fact, and otherwise leave a healthy doc alone.
8. Produce a synthesized findings list where each item names the problem, its location, and why it matters.

## Phase 3: apply or report

1. Under `--check`, apply nothing: list the fixes you would make and the decisions you would raise, then go to Phase 4.
2. Otherwise work through the findings, matching each document's existing voice and structure.
3. Do not narrate each edit; account for all of them in the recap.

### Apply without asking

- Fix factual drift: a wrong or renamed command, a dead internal link, a stale path, a wrong config key, an outdated version.
- Fix drift in generated surfaces too: a moved badge target, a snippet calling a removed API.
- Fix single-resolution voice defects: remove every em and en dash, strip decorative emoji, lower Title Case headings to sentence case, straighten curly quotes.
- Cut clear filler and restated-heading warm-up lines.
- Cut obvious bloat such as a padded conclusion or a duplicated install section a canonical copy already covers.
- Remove a dead or zero-content git-tracked doc with `git rm` so it stays recoverable.
- Rewrite a heavily AI-voiced section through `humanizer` when available, keeping all of the original's content and specifics.

### Ask instead of applying

- Two or more solutions carry real tradeoffs: restructure a guide or leave it, scope overlapping docs, pick the canonical near-duplicate.
- Intent you cannot verify: a documented feature absent from the code may be planned, deliberately kept, or stale.
- A rewrite would change meaning, drop information, or override an authorial choice you cannot confirm is wrong.
- A legal claim is at stake: fix a broken `LICENSE` link or a typo, but flag a license mismatch instead of editing the claim or inventing the file.
- A removal would not be git-recoverable, because the file is untracked or the scope is not a git repo.

Pose each as a plain question with concrete options and a recommended default.

Keep resolving everything else while a decision waits, and block only when the rest depends on the answer.

### After editing

1. Scan every file you edited for an em dash (U+2014) and an en dash (U+2013); any hit means the file is not done.
2. When the repo has `markdownlint`, `vale`, `textlint`, or a link checker and running it is cheap, run it on touched files and fix failures you caused.
3. When the project tests runnable snippets (doctests, MDX examples, a `test-examples` script), run that check too.
4. Never commit or push; the commit boundary belongs to the user.

## Phase 4: recap

1. Lead with a one-line verdict.
2. Report scope: the resolved root, the scope path if any, and the mode (applied or `--check` audit).
3. Report what changed, one line each with the reason; under `--check`, retitle it "Would change" and list the fixes instead.
4. Report decisions pending, with their options, whenever a question is unanswered.
5. Report follow-ups when any exist: a `sync-agents` handoff, a generated doc to regenerate, a code-looks-wrong flag, an unverified external link.
6. When everything was unambiguous and applied, keep the recap to the verdict and the change list.
7. When the work is commit-worthy, offer a Conventional Commit message and leave the commit to the user.

## Bundled resources

- [references/doc-inventory.md](references/doc-inventory.md): the in-scope and out-of-scope file map plus each doc's role. Loaded in Phase 1.
- [references/prose-review.md](references/prose-review.md): currency, coherence, signal density, writing voice, constraint compliance. Loaded in Phase 2.
