# Agentic architecture review

The rubric for reviewing how a repository's agentic files are designed and organized. Loaded in Phase 2 of sync-agents.

## Contents

- [The agents.md standard](#the-agentsmd-standard): the rules that bind a review
- [File taxonomy](#file-taxonomy): what each file is for
- [Standard project wiring](#standard-project-wiring): the layout to scaffold and repair against
- [Architecture checks](#architecture-checks): the judgment calls
- [Instruction style](#instruction-style): the shape of every line
- [Signal-density checks](#signal-density-checks): what to cut
- [Skill provenance](#skill-provenance): third-party sources and pinning
- [Constraint compliance](#constraint-compliance): budgets and local rules

## The agents.md standard

Treat `AGENTS.md` as the portable, tool-neutral source of truth: plain Markdown, no required fields, no mandated sections, no frontmatter requirement.

- When a layout nests, the `AGENTS.md` nearest the edited file applies, so review root and nested files as one hierarchy.
- When a file claims to override an explicit prompt, flag it; documentation steers and never overrides a direct instruction.
- When `AGENTS.md` names a build, test, or lint command, verify it still runs, because agents execute the checks a file lists.
- When the README carries agent-only instructions, flag the misplacement and leave the README itself to the `sync-docs` skill.

## File taxonomy

Map every agentic file to a role. A file with no clear role is a finding.

### Entrypoints

- Root `AGENTS.md` holds context an agent cannot infer from the repository: architecture, conventions, workflow, non-obvious commands, hard constraints.
- Nested `AGENTS.md` holds only a subproject's deltas; when it largely repeats the root, flag the redundancy.
- `CLAUDE.md` and other tool entrypoints stay thin pointers to `AGENTS.md`; when one forks it, flag the fat entrypoint.
- When a rule file (`.agents/rules/*`, `.github/instructions/*`) is path-gated, check the scope and the frontmatter validity for every tool that reads it.
- When one physical rule file is consumed twice by a single tool, flag the duplicate route.

### Trees and configuration

- `.agents/**` is the canonical home for rules, skills, commands, hooks, output styles, and specs; check it is organized by kind and nothing is orphaned.
- When `.agents/**` holds a plans or specs backlog, check each entry against the repository's completion convention and flag a plan for a shipped feature.
- When `.mcp.json` or a tool variant declares MCP servers, verify every command, arg, path, and env var resolves.
- When `AGENTS.md` and the MCP config disagree, flag documented-but-unconfigured and configured-but-undocumented servers.
- Each `SKILL.md` carries a crisp triggering description and a lean body with detail in references; check the description triggers on the intended use.
- `.claude/**` holds settings, commands, subagents, and skills; check it stays consistent with `AGENTS.md` instead of duplicating it.
- When a `.claude/commands/*.md` file outgrows one file, record a migration finding, because new procedures belong in a skill folder.
- When a config is a symlink, edit and audit the target; when the target resolves outside the scope, treat it as read-only context and flag the crossing.

## Standard project wiring

The default layout to scaffold when a repository has no agentic wiring, and the baseline for repairing a partial one.

A convention the repository declares wins over this default. The procedure that creates it lives in [project-scaffold.md](project-scaffold.md).

- `AGENTS.md` at the root, per the taxonomy above.
- `CLAUDE.md` at the root containing exactly `@AGENTS.md`, never a symlink, with Claude-only additions allowed below the import.
- `.agents/` as the tool-neutral canonical tree for rules, skills, hooks, and specs, with hand-authored content tracked by default.
- `.agents/skills/.gitignore` containing `/*/` as the only allowlist, plus an ignored `artifacts/` directory when one is first created.
- `.claude/` as a real directory for Claude-specific files, with per-asset symlinks created only when the target exists.
- Those symlinks are `rules -> ../.agents/rules`, `skills -> ../.agents/skills`, and `hooks -> ../.agents/hooks`.
- `.claude/.gitignore` listing the runtime entries `settings.local.json` and `worktrees/`, leaving the root `.gitignore` untouched.
- No other entrypoint: add a route such as `.github/instructions`, or a tool directory, only after verifying that tool loads it at project scope.

### Repair rules

1. Create only what is missing and never overwrite; scaffolding and repair are the same operation.
2. Track the symlinks themselves so clones keep the wiring.
3. For a conflicting but working layout, such as a fat `CLAUDE.md` or a whole-directory `.claude -> .agents` symlink, flag it rather than migrate silently.

## Architecture checks

For each check, ask whether the current arrangement is the best one for an agent to work with.

- Source-of-truth integrity: is `AGENTS.md` authoritative, do entrypoints point to it rather than fork it, and do any files contradict each other?
- Earned place: does each file have a distinct purpose, audience, and content, or does a tool config already cover it?
- Grouping and splitting: is related guidance together, is anything long enough to split or fragmented enough to merge, and is the root/nested division clean?
- Progressive disclosure: are entry files scannable with depth in references kept one level deep, so agents read complete files?
- Tool fit: is each job done by the right mechanism (skill, command, scoped rule, prose) with valid frontmatter, working includes, and forward-slash paths?
- Loader graph: for each tool, identify startup, scoped, manual, include, and symlink routes, then flag duplicate physical files and files no route can reach.
- Skill catalog: measure metadata exposed before selection; flag verbose descriptions, duplicate triggers, disabled or shadowed skills, and lockfile drift.
- Coverage: is anything an agent needs missing, such as setup, non-obvious build steps, conventions, or the repository's workflow?

For loader evidence in Claude Code, when a route is disputed, prefer an `InstructionsLoaded` hook log over inference.

## Instruction style

The shape that raises adherence. Apply it to every hand-written agentic file: entrypoints, rules, skill bodies, references, and agent definitions.

### Line shape

- Write one directive per line. A list item that carries a second directive splits into two items.
- Put the trigger first, as "When X, do Y". A rule without a trigger reads as always-on and dilutes the rest.
- Keep a list item under 160 characters and at most two sentences; the second sentence is the reason, kept only when it changes the decision.
- Name the exact path, symbol, flag, command, or number instead of describing it.
- Avoid bold lead-ins, arrow chains, nested clauses, and rationale paragraphs.

### Structure and placement

- Name the scope in a header. A section holds at most eight items; more means a split or a reference.
- Use a list for independent rules and numbered steps for a sequence an agent executes. Use a short paragraph only for context that no line can carry alone.
- Move examples to a reference loaded on demand and cite it by relative path from the entry file.
- Cut history, comparisons, and justification, or move them to a reference; they are not instructions.
- Scope a rule to the paths where it fires instead of keeping it always on.

## Signal-density checks

Every always-on token is paid each session, so scope a rule to where it fires instead of making it global.

The test for keeping a line: would an agent do worse without it?

- When a linter, formatter, type checker, or CI config already enforces a rule, point to the tool instead of restating the rule.
- When a line is generic advice such as "write clean code" or restated language documentation, cut it or replace it with the specific local rule.
- When content is readable off `package.json` or the directory tree, cut it unless it carries a non-obvious twist.
- When a placeholder section, an unresolved TODO, or an instruction for an unused tool remains, cut it as stale scaffolding.
- When build or scratch output (`tmp/`, logs, `node_modules/`, `dist/`, `.next/`) sits under `.agents/` or `.claude/`, flag it unless git-ignored.

## Skill provenance

- Record for every third-party skill its source repository, whether the lockfile pins a tag or revision, and the revision reviewed.
- When a source floats on a default branch, flag it on its own, because the next update pulls whatever that branch holds into files that steer the agent.
- Pin a third-party skill to a tag or revision where the manager supports it; where it does not, record the reviewed revision in the audit.
- Read the diff of the installed bodies before accepting an update, and review it as a code change rather than a docs refresh.

## Constraint compliance

Use [context-budgets.md](context-budgets.md) as the default envelope even when the repository declares no limits; a stricter local budget overrides it.

Report compliance as concrete pass/fail items so the proposal shows what is off and what fixing it costs.

- Measure every audit with `scripts/count_tokens.py`, using the relevant profile or explicit limits.
- Flag files over budget and files with hard-wrapped prose, then propose a split, a trim, or an unwrap instead of accepting the excess.
- Check the structure and naming the repository prescribes: section order, file naming, folder layout.
- Name a skill with a gerund or noun phrase, lowercase and hyphenated only, at most 64 characters, with no reserved word.
- Write a skill description in third person stating what plus when, at most 1024 characters.
- Check voice and vocabulary rules: tone, banned words, formatting conventions.
- Check project-specific conventions such as a thin-`CLAUDE.md` rule, a single-source rule, or a spec-first workflow.
