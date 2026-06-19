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
- In autonomous runs with no one to ask, state the assumption, take the most defensible reading, proceed, and record the decision and its reversal cost in the summary. Hard-stop only for irreversible or destructive actions (data loss, prod writes, schema drops, secret rotation).

## 2. Simplicity first

- Build the minimum that solves the stated problem. No speculative features, abstractions, configurability, or props "for later". If 200 lines could be 50, rewrite before presenting. Test: would a senior engineer call this overcomplicated?
- Inline single-use logic; don't wrap it in helpers or generics. But pull genuinely shared primitives, design tokens, and cross-cutting hooks into the shared layer on first reuse; duplicating a shared component is the costlier mistake.
- Don't guard the impossible; do guard every real boundary. Skip defensive code for states unreachable by construction: enforce those with types, exhaustive matches (e.g. a `switch` with an `assertNever` default), and schema validation at the edges. But handle every real I/O and concurrency boundary: network/timeout/abort, hydration, races, third-party failure. Every async UI surface needs loading, empty, error, and error-boundary states.
- **Never add comments to code.** Name things so the code reads without them; if a line needs a comment to be understood, rewrite the line. Exactly two exceptions: (a) a JSDoc block, and only when the surrounding code already uses JSDoc for similar symbols (match the existing convention, don't introduce it); (b) a linter-disable directive (`eslint-disable`, `# noqa`, `rubocop:disable`, etc.), and only when suppressing the rule is strictly necessary. Everything else (explanatory, sectioning, TODO, or commented-out code) is banned. This covers new comments; leaving existing ones is governed by the surgical-changes rule below.

## 3. Surgical changes

- Touch only lines that trace to the request. No drive-by refactors, comment edits, or reformatting. Every changed line must trace to the request.
- Formatters own style: run the repo's formatter; never hand-match quotes, semicolons, or spacing.
- Clean up only your own mess: remove imports/variables/functions YOUR change orphaned. Leave pre-existing dead code; flag it instead of deleting it unless asked.
- Fix adjacent latent bugs, not adjacent style: dependency-array, server/client-boundary, and missing-`key` violations next to your change are bugs worth fixing; whitespace is not.
- Never hand-edit generated files (UI component generators, route trees, ORM clients, OpenAPI/GraphQL codegen); regenerate them. No drive-by lockfile bumps or shared-dependency changes.

## 4. Goal-driven execution

- Define success criteria before implementing, then loop until verified. Turn vague tasks into checkable ones: "add validation" → write the failing test for invalid input, then make it pass; "fix the bug" → reproduce it with a failing test, then resolve it; "refactor X" → confirm the suite is green before and after.
- Verify against a machine-checkable criterion, not "it works". Run what the repo provides and what fits the change, roughly in order:
  1. **Types**: the project's typecheck passes with zero errors (plus exhaustiveness where the language supports it).
  2. **Lint**: the project's linter passes with zero errors.
  3. **Tests**: unit/integration for logic changes; write the failing test first for bug fixes.
  4. **Behavior**: flows via browser automation (`agent-browser`/Playwright); visual and animation work via screenshot plus `prefers-reduced-motion`; components via accessibility checks (axe). A passing typecheck is not visual verification.
- The rungs above are illustrative; translate them to the project's stack, e.g. `mypy`/`pytest`, `rubocop`/`rspec`, `go vet`/`go test`, `cargo check`/`cargo test`.
- Use the project's own scripts and package manager: detect it from the lockfile (`pnpm-lock.yaml` → pnpm, `package-lock.json` → npm, `bun.lockb` → bun) and run its declared scripts; never assume one. Likewise detect the test runner from the repo (`jest`/`vitest` config, `pytest.ini`/`pyproject`, `Gemfile`, `go test`) instead of assuming. For multi-step work, state a numbered plan with a verify step each, then loop until green and report which rungs ran and their results.
- Never introduce secrets into code or commits (`.env` values, API keys, tokens); keep them in env vars or a secret store. The `security-guidance` plugin covers deeper checks.

## 5. Never commit unless asked

- **Do not run `git commit`, `git push`, `git add` + commit, or any history-writing git command unless the prompt explicitly requests it** (words like "commit", "push", "land it", "open a PR"). A request to write, fix, refactor, apply, or update code is NOT a request to commit. Finish the work, leave it in the working tree, and stop. This holds even when the change is verified, green, and obviously commit-worthy, and even across a multi-turn task where you committed earlier with permission: each commit needs its own go-ahead unless the user said to keep committing.
- When you believe the work is commit-worthy, do not commit and do not emit a `git` command to run. Instead close your reply with three parts: (1) a `### Changes` list, one bullet per changed file as a clickable link plus a **short single-sentence** description; (2) the commit message **alone** in a fenced code block (the message only, no `git add`/`git commit` wrapping), following the repo's commit conventions (in the dotfiles repo, the per-repo types in `dotfiles.instructions.md`); (3) a short question asking whether to run the commit. The shape:

  ````
  ### Changes

  - [engineering.instructions.md:47](.agents/rules/engineering.instructions.md:47) - reworked the suggested-commit-block spec.

  I suggest this commit message:

  ```
  agents: avoid code comments and em-dashes
  ```

  Want me to run the commit?
  ````

  For multiple commits, give each its own message block and group the changes under it:

  ```
  ### Changes

  **docs: drop the model-selection section**
  - [AGENTS.md](AGENTS.md) - removed the stale model-selection paragraph.
  - [README.md](README.md) - dropped the matching README entry.

  **fix: handle empty input** (in `~/Developer/@scope/other-repo`)
  - [src/app.ts](src/app.ts) - guarded against empty input.

  Want me to run these commits?
  ```

- If a task legitimately needs intermediate commits to proceed (e.g. a rebase, a bisect, or the user said "commit as you go"), that standing instruction counts as explicit permission for the scope they described; do not extend it beyond that scope.
