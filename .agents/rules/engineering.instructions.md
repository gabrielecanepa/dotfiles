---
description: 'Use for code work. Enforces minimal scope, surgical diffs, verification, and commit safety.'
applyTo: '**'
---

# Engineering guidelines

## Before coding

- Apply precedence: user request, repository conventions, this rule, then existing style. Define observable success and assumptions or tradeoffs that change it.
- Use the simplest viable rung: no change, standard library, native feature, installed dependency, then new code. Check official docs for uncertain APIs.
- Choose the safest reversible interpretation and record it. Stop for destructive, irreversible, production, or secret-changing actions.
- Delegate only bounded, independent, authorized work with the root, scope, expected return, and stop conditions. Retain architecture, risk, synthesis, and final verification.

## Minimum correct code

- Build only what the request needs. No speculative abstractions, options, props, compatibility layers, or duplicated single-use logic.
- Model impossible states with types. Guard I/O and concurrency failures, timeouts, cancellation, hydration, and races. Async UI needs loading, empty, error, and boundary states.
- **Do not add code comments.** Prefer clear names and structure. Exceptions: an existing local JSDoc convention, a necessary linter-disable directive, or a required file header. No explanatory, section, TODO, or commented-out code.
- Keep agentic files concrete, scoped, and free of generic or formatter-enforced advice. Repository agentic docs must be self-contained, with no undeclared machine dependency.
- Keep large features in separate `spec`, `plan`, and `tasks` artifacts, split by phase or subsystem at the context budget. Never load scratch plans globally.
- Follow `sync-agents` when creating or repairing agentic files or skills.

## Surgical diffs

- Touch only lines required by the request. A symbol rename changes identifiers only, never comments or whitespace. Do not refactor adjacent code; configured formatters own style.
- Remove only dead code created by the change. Flag pre-existing dead code unless asked. Fix an adjacent correctness bug only when it directly intersects the change.
- Never hand-edit generated code, lockfiles, route trees, clients, or schemas. Run the owner.
- Update project docs when the change alters behavior, commands, paths, or documented architecture.

## Verification

- Reproduce bugs before fixing them and add regression coverage when practical. Establish a green baseline before behavior-preserving refactors.
- Detect and run the relevant repository checks, normally types, lint, tests, then behavior. Do not assume the package manager or runner.
- Verify UI changes in the running app through browser automation and capture screenshot evidence. Typecheck cannot verify layout, interaction, animation, accessibility, or auth. Reuse the configured server and follow `browser.instructions.md`.
- After multi-file or behavior-changing work, spawn a reviewer subagent on the diff with strict criteria: correctness, security, spec compliance, and repository conventions. Every finding must cite file:line and a concrete failure scenario.
- Confirm each finding before fixing it, cap review at two rounds, and report unresolved findings in the handoff instead of iterating further.
- Report exact commands and outcomes, separating change-caused failures from baseline noise.
- Never put secrets in source, command args, logs, or commits.

## Commit boundary and handoff

- Never run `git add`, `git commit`, `git push`, or another history-writing command unless the current prompt explicitly asks. Implementation is not permission, and permission does not carry to a later commit without standing scope.
- For commit-worthy uncommitted work, including "finish up," render this exact handoff, never describe it: a `### Changes` list with one clickable file link and one short sentence per file; the proposed commit subject alone in a fenced block; then a short question asking whether to commit. Do not emit a git command.

````markdown
### Changes

- [file:line](path/to/file:line) - describes the resulting behavior.

I suggest this commit message:

```text
type: imperative subject
```

Want me to run the commit?
````

Use the repository's commit convention. Group separate commits into separate change lists and message blocks.
