# Agentic architecture review

The rubric for reviewing how a repository's agentic files are designed and organized. Loaded in Phase 2 of sync-agents.

## Contents

- [The `agents.md` standard in brief](#the-agentsmd-standard-in-brief)
- [File taxonomy](#file-taxonomy): what each file is for
- [Standard project wiring](#standard-project-wiring): the default layout to scaffold and repair against
- [Architecture checks](#architecture-checks): the judgment calls
- [Signal-density checks](#signal-density-checks-what-to-cut): what to cut
- [Constraint compliance](#constraint-compliance): budgets and local rules

## The `agents.md` standard in brief

`AGENTS.md` is an open, plain-Markdown format, "a README for agents." It has no required fields, no mandated sections, no frontmatter requirement; projects use whatever headings carry the most signal. It is stewarded as an open standard (under the Linux Foundation's Agentic AI Foundation) and read by most major coding agents, so treat it as the portable, tool-neutral source of truth rather than tying instructions to one vendor's file.

Rules that matter for review:

- **Nearest wins.** In a monorepo or any nested layout, the `AGENTS.md` closest to the file being edited applies. So nested `AGENTS.md` files are legitimate and often correct: each subproject ships tailored instructions. Review them as a hierarchy: the root holds what's true everywhere, nested files hold only what differs.
- **Explicit prompts override files.** Documentation steers; it never overrides a direct instruction. Don't write docs that try to.
- **Listed checks get run.** If AGENTS.md names build/test/lint commands, agents will execute and try to pass them. So those commands must be correct and current: a stale command here is worse than none.
- **Complements the README, doesn't replace it.** README is for humans; AGENTS.md carries the agent-specific context that would clutter a README. This skill audits only the agentic side, but the split is the reason a README-carrying-agent-instructions finding matters.

## File taxonomy

Map every agentic file to a role. A file with no clear role is a finding.

- **`AGENTS.md` (root)**: the source of truth. High-signal, project-specific context an agent can't infer from the repo itself: architecture, conventions, the spec-first workflow, non-obvious commands, hard constraints.
- **`AGENTS.md` (nested)**: only the deltas for a subproject. If a nested file largely repeats the root, that's redundancy to flag.
- **`CLAUDE.md` / tool entrypoints**: thin pointers to AGENTS.md, not parallel copies. The default to enforce (see [Standard project wiring](#standard-project-wiring)): `CLAUDE.md` contains only an `@AGENTS.md` include (or the tool's equivalent). Multiple fat, drifting entrypoints are the exact problem AGENTS.md exists to solve.
- **`.agents/**`**: the canonical home for agentic assets (rules, skills, commands, hooks, output styles, specs). Check it's organized by kind, each asset is reachable and referenced, and nothing is orphaned. If it holds a plans/specs backlog, check entries against any completion convention the repo declares: a plan for a shipped feature left in `plans/` is dead weight to flag, not a delta to keep.
- **Rules / instruction files** (`.agents/rules/*`, `.github/instructions/*`): scoped guidance that loads on a path glob. Check the scope is right (a rule that should be always-on vs. path-gated), the frontmatter is valid for every tool that reads it, and the same physical file isn't consumed twice by one tool.
- **MCP config** (`.mcp.json` and tool variants): declares the MCP servers agents get. Each server's command, args, path, and referenced env vars must resolve, and the set should match any MCP servers AGENTS.md documents (documented-but-unconfigured, or configured-but-undocumented, is a finding).
- **Skills**: each `SKILL.md` should have a crisp description (the trigger), stay lean in the body, and push detail to references. Check skills are well-formed and that their descriptions actually trigger on the intended use.
- **`.claude/**`\*\*: settings, commands, subagents, skills. Claude Code merged custom commands into skills: a `.claude/commands/*.md` file still works, but new procedures belong in a skill folder, and a command that outgrows one file is a migration finding. Check it's consistent with AGENTS.md and not duplicating it. Watch for symlinked configs whose target is the real source: edit and audit the target, not the link. If a symlink's target resolves outside the resolved scope, treat it as read-only context and flag the crossing rather than editing across the boundary.

## Standard project wiring

The default layout to scaffold when a repository has no agentic wiring, and the baseline for repairing a partial one. A convention the repository itself declares wins over this default. The procedure that creates it lives in [project-scaffold.md](project-scaffold.md).

- **`AGENTS.md`** at the root: the canonical file per the taxonomy above.
- **`CLAUDE.md`** at the root containing exactly `@AGENTS.md`. Claude Code reads `CLAUDE.md`, not `AGENTS.md`; the one-line import is its documented bridge, preferred over a symlink because it survives Windows checkouts and admits Claude-only additions below the import.
- **`.agents/`**: the tool-neutral canonical tree (rules, skills, hooks, specs). Hand-authored content is tracked by default; the only allowlist sits at `.agents/skills/.gitignore` (`/*/`), because installed skills behave like `node_modules` and reinstall from `skills-lock.json`. An `artifacts/` directory is ignored when first created.
- **`.claude/`**: a real directory for Claude-specific files (`settings.json`, `commands/`, runtime state) with per-asset symlinks into the canonical tree (`rules -> ../.agents/rules`, `skills -> ../.agents/skills`, `hooks -> ../.agents/hooks`) created only when the target exists. Its own `.claude/.gitignore` lists the runtime entries (`settings.local.json`, `worktrees/`) so sessions never dirty the repository and the root `.gitignore` stays untouched. Git tracks the symlinks themselves, so clones keep the wiring.
- **No other entrypoints.** Codex, Copilot, Cursor, and most other agents read `AGENTS.md` natively. A scoped-rule route (`.github/instructions`) or any tool directory is added only for a tool the repository actually uses, after verifying the tool loads that route at project scope.

Scaffolding and repair are the same operation: create only what is missing and never overwrite. Flag a conflicting but working layout (a fat `CLAUDE.md` that forks `AGENTS.md`, a whole-directory `.claude -> .agents` symlink from an older convention) as a finding to resolve, not something to silently migrate.

## Architecture checks

The judgment calls. For each, the question is whether the _current_ arrangement is the best one for an agent to work with.

- **Source-of-truth integrity.** Is AGENTS.md genuinely authoritative? Do entrypoints point to it rather than fork it? Any contradictions between files?
- **Does each file earn its place?** Purpose, audience, and unique content. A file that duplicates another, or that no one reads, or that a tool config already covers, is a candidate for merge or deletion.
- **Grouping and splitting.** Is related guidance together and unrelated guidance apart? Is anything so long it should split (progressive disclosure: lean entry file, detail in references)? Is anything so fragmented it should merge? In monorepos, is the root/nested division clean?
- **Progressive disclosure.** The entry files (AGENTS.md, each SKILL.md) should be scannable; depth belongs in referenced files loaded on demand. Flag entry files that try to hold everything. Keep references one level deep from the entry file so agents read complete files instead of previewing nested ones.
- **Tool fit.** Are the right mechanisms used for each job: a skill where a skill belongs, a command where a command belongs, a scoped rule where a rule belongs, AGENTS.md prose only for what can't be a tool or skill? Are they used correctly (valid frontmatter, working includes, correct paths, forward-slash paths)?
- **Loader graph.** For each tool, identify startup files, scoped files, manual routes, includes, and symlink targets. Flag duplicate physical files loaded through multiple routes and files that no configured route can discover. In Claude Code, an `InstructionsLoaded` hook can log which instruction files loaded and why; prefer that evidence over inference when a route is disputed.
- **Skill catalog.** Measure the metadata exposed before a skill is selected. Flag verbose descriptions, duplicate triggers, disabled or shadowed skills, and lockfile entries that do not match installed folders.
- **Coverage.** Is anything an agent needs missing: setup, non-obvious build steps, conventions, gotchas, the workflow the repo follows? Gaps are as much a finding as bloat.

## Signal-density checks (what to cut)

Bloated and generically-written context files measurably reduce agent success and raise cost. Every always-on token is paid each session, most of which never use the rule, so prefer scoping a rule to where it fires over making it global. Bias toward cutting:

- **Toolchain duplication.** If a linter, formatter, type checker, or CI config already enforces a rule, AGENTS.md should not restate it: it should point to the tool. Describe only behavioral rules no tool can express.
- **Generic advice.** "Write clean code," "follow best practices," restated language docs: zero signal. Cut or replace with the specific, local rule.
- **Obvious-from-the-repo content.** The stack and structure an agent can read off `package.json` and the directory tree don't need narrating unless there's a non-obvious twist.
- **Stale scaffolding.** Placeholder sections, TODOs that never resolved, instructions for tools no longer used.
- **Committed scratch or build output.** Session `tmp/` dirs, logs, or generated folders (`node_modules/`, `dist/`, `.next/`) tracked under `.agents/`/`.claude/`: flag as dead weight and confirm they're git-ignored, not committed.

The test for keeping a line: would an agent do worse without it? If not, cut it.

## Constraint compliance

Use [context-budgets.md](context-budgets.md) as the default envelope even when the repository declares no limits. A stricter local budget overrides it. These are review thresholds, not a claim that a token count guarantees model quality. Budgets and optimization decisions use estimated tokens only; the lines and bytes in the report are informational.

- **Token budgets**: measure every audit with `scripts/count_tokens.py`, using the relevant profile or explicit limits. Flag files over budget, and files with hard-wrapped prose, and propose a split, trim, or unwrap rather than silently accepting the excess.
- **Structure / naming conventions**: section order, file naming, folder layout the repo prescribes. For skills, the `agents.md`/Anthropic conventions apply: gerund or noun-phrase name, lowercase-hyphen only, max 64 chars, no reserved words; description in third person, what plus when, max 1024 chars.
- **Voice and vocabulary rules**: tone, banned words, formatting conventions.
- **Project-specific conventions**: e.g. a thin-CLAUDE.md rule, a single-source rule, a spec-first workflow. Check files conform.

Report compliance as concrete pass/fail items so the proposal can show exactly what's off and what fixing it costs.
