# Engineering workflow and verification

Conditional workflow routed from `../AGENTS.md`. Read before coding, file changes, reviews, commands, or delegation; apply the sections relevant to the task.

## Before editing

- Run `git status --short -uall` before changes or review; preserve modified and untracked files outside the requested scope.
- Follow existing style where repository instructions and configuration are silent.
- Prefer no change, standard library, native features, installed dependencies, then new code.
- Build only what is required: no speculative abstractions, options, or compatibility layers.
- Search shared layers before adding a helper, constant, or hook; promote only for a second consumer.
- Leave no explanatory comments, section markers, or TODOs; add JSDoc only where adjacent code already uses it.
- `.git/local/` (`$(git rev-parse --git-common-dir)/local`) holds user-owned untracked files; never commit, delete, or create it unasked.

## Surgical diffs

- Touch only required lines; a rename changes identifiers only, never comments, whitespace, or adjacent code.
- Remove only newly dead code and flag pre-existing dead code; fix an adjacent bug only when it intersects the change.
- Re-read a file the user edited before continuing; their edits are locked intent.
- Regenerate artifacts with their tool; update docs when behavior, commands, or paths change.

## Code safety

- Use types for impossible states; guard I/O, timeouts, cancellation, and races.
- Give async UI loading, empty, and error states.

## Local environment and toolchain

- The host is macOS on Apple Silicon with Homebrew at `/opt/homebrew`; the editor and terminal are VS Code and Ghostty.
- Project code lives under `~/Developer`, client projects under `~/Developer/@<client>`; `$HOME` is the dotfiles repository.
- `profile`, `plugin`, `brew`, `mas`, `lts`, `deps`, and `dotfiles` are zsh plugin functions under `~/.zsh`, not binaries.
- Runtimes come only from the `nodenv`, `pyenv`, and `rbenv` shims; never add another version manager.
- The default Node package manager is pnpm through Corepack; the project's lockfile always wins.
- Run the repository's configured formatter; otherwise use oxfmt for JS, TS, CSS, and JSON, or shfmt and shellcheck for shell.
- For other files, follow `.editorconfig`.

## Verification

- Add regression coverage before fixing a bug; get a green baseline before a refactor.
- Run types, lint, tests, then behavior; report the commands and separate new failures from baseline noise.
- After fixing a bug, grep for the same shape and answer for every match: fix it, safe to leave and why, or ask.
- For UI, verify with browser automation and screenshots per `../rules/browser.md`; static checks cannot prove layout or interaction.

## Delegation

- Delegate bounded, independent, read-only tasks to the configured explorers and reviewers, never nested, at most 3 concurrent.
- Give each delegate a root, a scope, the evidence to return, and a stop condition.
- The primary owns writes, architecture, synthesis, and verification.
- Parallel writers need explicit permission, isolated worktrees, and disjoint files.
- Workflow and orchestration stages never run Fable-class models, even with approval; a warranted Fable-class review runs afterwards as a standalone subagent.
- Spawning a standalone Fable-class subagent requires asking first; context-inheriting forks cannot change model and are exempt.

## Reviewer protocol

- After multi-file or behavior changes, run a reviewer subagent for correctness, security, spec compliance, and conventions.
- Pass the complete diff when the reviewer's tools cannot read the Git history.
- Every finding cites `file:line` with a failure scenario; confirm each one before acting on it.
- Stop after two review rounds and hand off unresolved items.

## Running services

- Before starting a dev server or service, check for one already running: a listening port, an open terminal, an open tab. Reuse it.
- On a port-in-use error, identify the listener and verify it is the intended app before testing; never kill it or switch ports.
- Start a new instance only when no running one can serve the change, and ask before restarting one you did not start.

## Evidence layers

- Source, CI, package contents, installed runtime, release assets, registry, and deployed state are separate layers; one never implies another.
- Report each layer checked and name the rest as gaps before calling anything released, published, installed, or done.

## Commit decision

- Read the unpushed history first: `git log --oneline @{upstream}..`, or the whole branch when no upstream exists.
- A standalone change, feature, or fix gets a new commit.
- A continuation of unpushed work (the rest of a feature, a fix on top, review follow-ups) is proposed as an amend or squash.
- Name each amend or squash target by its short hash and subject.
- Mixed concerns get the fewest commits, one even when its scope fits loosely; split only when the repository's history keeps such concerns apart.
- Never rewrite pushed history unless asked; when the matching commit is pushed, propose a new commit.
- When the work addresses a GitHub issue, reference it in the footer (`Closes #12`, `Fixes #12` for bugs, `Refs #12` for partial work) per `../rules/github.md`.
