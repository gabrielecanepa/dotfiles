---
description: 'Always on: scope, diffs, verification, commit safety.'
applyTo: '**'
---

# Engineering

## Before coding

- Apply precedence: user, repository, this rule, existing style.
- Prefer: no change, standard library, native features, installed dependencies, new code.
- Stop before destructive, production, or secret-changing actions.
- Treat review, inspect, analyze, diagnose, and assess as read-only; check `git status --short -uall` and leave modified files alone.
- Delegate only read-only work, at most 3 concurrent, per `~/.agents/references/verification.md`.

## Minimum correct code

- Build only what is required: no speculative abstractions, options, or compatibility layers.
- Search shared layers before adding a helper, constant, or hook; promote only for a second consumer.
- Use types for impossible states; guard I/O, timeouts, cancellation, and races; give async UI loading, empty, and error states.
- Leave no explanatory comments, section markers, or TODOs; add JSDoc only where adjacent code already uses it.

## Surgical diffs

- Touch only required lines; a rename changes identifiers only, never comments, whitespace, or adjacent code.
- Remove only newly dead code and flag pre-existing dead code; fix an adjacent bug only when it intersects the change.
- After fixing a bug, grep for the same shape and answer for every match: fix it, safe to leave and why, or ask.
- Re-read a file the user edited before continuing; their edits are locked intent.
- Regenerate artifacts with their tool; update docs when behavior, commands, or paths change.

## Verification

- Add regression coverage before fixing a bug; get a green baseline before a refactor.
- Run types, lint, tests, then behavior; report the commands and separate new failures from baseline noise.
- Reuse a running dev server; a port-in-use error means the app is up, so verify against it, never kill it or switch ports.
- Verify UI with browser automation and screenshots per `browser.md`; static checks cannot prove layout or interaction.
- After multi-file or behavior changes, run a reviewer and report evidence layers per `~/.agents/references/verification.md`.
- Never write secrets in code, logs, or commits.

## Commit handoff

- For commit-worthy uncommitted work, read `~/.agents/references/commit-handoff.md` completely and render its block, never a description of it, even in a plan.
