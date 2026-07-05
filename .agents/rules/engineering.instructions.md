---
description: 'Use when writing, reviewing, or refactoring code in ANY repository. Code-execution discipline: think before coding, simplicity, surgical diffs, and goal-driven verification. Skip for trivial one-liners and pure Q&A.'
applyTo: '**'
---

# Engineering Guidelines

Applies when writing, reviewing, or refactoring code; skip for trivial one-liners and pure Q&A. Precedence: **explicit user instruction > the target repo's conventions > the guidance below > existing file style.** These rules apply to ALL code you write, including edits inside legacy files; match existing style only where no convention exists. This is line- and output-level discipline; it does not restate the reasoning rules in `behavior.instructions.md`.

## 1. Think before coding

- Surface assumptions and tradeoffs in the plan phase. Ask questions there, not mid-implementation.
- If multiple interpretations exist, present them; don't pick one silently.
- If a simpler approach exists, say so and push back, with the cost of the complex path (maintenance, coupling, performance).
- **Default to industry-standard patterns** for structure, naming, and API shape (the precedence chain still governs). When the idiomatic choice is genuinely unknown, research it (official docs via `context7-mcp`, established community standards) before writing instead of guessing; when one drove a non-obvious choice, name the pattern and cite the source in the summary.
- In autonomous runs with no one to ask, state the assumption, take the most defensible reading, proceed, and record the decision and its reversal cost in the summary. Hard-stop only for irreversible or destructive actions (data loss, prod writes, schema drops, secret rotation).

## 2. Simplicity first

- Build the minimum that solves the stated problem. No speculative features, abstractions, configurability, or props "for later". If 200 lines could be 50, rewrite before presenting. Test: would a senior engineer call this overcomplicated?
- Before writing code, stop at the first rung that holds: needs to exist at all? stdlib does it? native platform feature? already-installed dependency? one line? only then, the minimum code that works. Between same-size approaches, pick the edge-case-correct one.
- Inline single-use logic; don't wrap it in helpers or generics. But pull genuinely shared primitives, design tokens, and cross-cutting hooks into the shared layer on first reuse; duplicating a shared component is the costlier mistake.
- Don't guard the impossible: skip defensive code for states unreachable by construction; enforce those with types, exhaustive matches (e.g. a `switch` with an `assertNever` default), and schema validation at the edges.
- Guard every real I/O and concurrency boundary: network/timeout/abort, hydration, races, third-party failure. Every async UI surface needs loading, empty, error, and error-boundary states.
- **Never add comments to code.** Name things so the code reads without them; if a line needs a comment, rewrite the line. Exactly three exceptions: (a) a JSDoc block, only when the surrounding code already uses JSDoc for similar symbols; (b) a linter-disable directive (`eslint-disable`, `# noqa`, `rubocop:disable`), only when suppressing the rule is strictly necessary; (c) a file-header doc block a repo rule explicitly requires (e.g. the dotfiles hooks). Explanatory, sectioning, TODO, and commented-out code are banned. This covers new comments; leaving existing ones is governed by section 3.
- **Authoring agentic files** (AGENTS.md, `*.instructions.md`, skills, any always-on context): the reader is a model and bloat lowers its success. Gate every add, change, or removal on two questions, keeping only what clears both: does it change the outcome for the better, and is this its most token-optimized form? Cut rationale prose first; prefer scoping a rule to where it fires over making it global; lead with the action, imperative and concrete. When unsure a cut is safe, verify with the bait scenarios in the `sync-agents` skill: a cold agent given only the text should still do the right thing.
- **Authoring a skill**: follow the portability standards in the `sync-agents` skill (works across its whole claimed domain, detects the toolchain from the repo, no machine- or repo-specific assumptions, crisp trigger description).

## 3. Surgical changes

- Touch only lines that trace to the request. No drive-by refactors, comment edits, or reformatting.
- Formatters own style: run the repo's formatter; never hand-match quotes, semicolons, or spacing.
- Clean up only your own mess: remove imports/variables/functions YOUR change orphaned. Leave pre-existing dead code; flag it instead of deleting it unless asked.
- Fix adjacent latent bugs, not adjacent style: dependency-array, server/client-boundary, and missing-`key` violations next to your change are worth fixing; whitespace is not.
- Never hand-edit generated files (UI component generators, route trees, ORM clients, OpenAPI/GraphQL codegen); regenerate them. No drive-by lockfile bumps or shared-dependency changes.
- Keep docs in sync in the same change: when a change alters anything the repo's `AGENTS.md` or `README` documents (routes, components, packages, actions, types, architecture, conventions), update those docs too. The `sync-agents` skill is for on-request audits; inline updates are the default.

## 4. Goal-driven execution

- Define success criteria before implementing, then loop until verified. Turn vague tasks into checkable ones: "add validation" → write the failing test for invalid input, then make it pass; "fix the bug" → reproduce it with a failing test, then resolve it; "refactor X" → confirm the suite is green before and after.
- Verify against a machine-checkable criterion, not "it works". Run what the repo provides and what fits the change, roughly in order:
  1. **Types**: the project's typecheck passes with zero errors (plus exhaustiveness where the language supports it).
  2. **Lint**: the project's linter passes with zero errors.
  3. **Tests**: unit/integration for logic changes; write the failing test first for bug fixes.
  4. **Behavior**: flows via browser automation (`agent-browser`/Playwright); visual and animation work via screenshot plus `prefers-reduced-motion`; components via accessibility checks (axe). A passing typecheck is not visual verification.
- Reuse a running app before spawning one: attach to the dev server and Chrome window the user already has open (it holds the logged-in session a blank window lacks). Start your own only when none is running, and target the existing preview window, never a new Chrome window.
- The rungs above are illustrative; translate them to the project's stack, e.g. `mypy`/`pytest`, `rubocop`/`rspec`, `go vet`/`go test`, `cargo check`/`cargo test`.
- Use the project's own scripts and package manager, detected from the lockfile (`pnpm-lock.yaml` → pnpm, `package-lock.json` → npm, `bun.lockb` → bun); never assume one. Likewise detect the test runner (`jest`/`vitest` config, `pytest.ini`/`pyproject`, `Gemfile`, `go test`). For multi-step work, state a numbered plan with a verify step each, then loop until green and report which rungs ran and their results.
- Never introduce secrets into code or commits (`.env` values, API keys, tokens); keep them in env vars or a secret store. The `security-guidance` plugin covers deeper checks.

## 5. Delegate the token-heavy work, keep the judgment

Delegation is an efficiency move, never a quality tradeoff: the delegated result must match or beat what you'd produce inline, or do it inline.

- Keep frontier work yourself (architecture, prioritization, ambiguity resolution, risk, synthesis, final review); delegate bounded token-heavy work to parallel subagents (repo inventory, wide search, docs extraction, log reduction, verification passes, mechanical edits).
- Delegate only independent slices; never point two agents at the same files; keep the immediate blocker inline.
- Give each subagent a self-contained packet: repo path, objective, scope, return format, and stop conditions (stop and report on contradicting code, repeated verification failure, out-of-scope needs, or missing evidence).
- Treat returns as evidence, not verdicts: reopen cited files, rerun the verification that matters, skim high-risk diffs; resolve disagreement at the orchestrator layer.

## 6. Never commit unless asked

- **Do not run `git commit`, `git push`, `git add` + commit, or any history-writing git command unless the prompt explicitly requests it** (words like "commit", "push", "land it", "open a PR"). A request to write, fix, refactor, apply, or update code is NOT a request to commit. Finish the work, leave it in the working tree, and stop. This holds even when the change is verified and obviously commit-worthy, and even across a multi-turn task where you committed earlier with permission: each commit needs its own go-ahead unless the user said to keep committing.
- When the work is commit-worthy, don't commit and don't emit a `git` command. Instead close your reply with three parts: (1) a `### Changes` list, one bullet per changed file as a clickable link plus a **short single-sentence** description; (2) the commit message **alone** in a fenced code block (no `git add`/`git commit` wrapping), following the repo's commit conventions (in the dotfiles repo, the per-repo types in `dotfiles.instructions.md`); (3) a short question asking whether to run the commit. The shape:

  ````
  ### Changes

  - [engineering.instructions.md:47](.agents/rules/engineering.instructions.md:47) - reworked the suggested-commit-block spec.

  I suggest this commit message:

  ```
  agents: avoid code comments and em-dashes
  ```

  Want me to run the commit?
  ````

  For multiple commits, give each its own message block with its changes grouped under it.

- If a task legitimately needs intermediate commits to proceed (e.g. a rebase, a bisect, or the user said "commit as you go"), that standing instruction is explicit permission for the scope they described; do not extend it beyond that scope.
