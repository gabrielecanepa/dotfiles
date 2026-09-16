# Project scaffold

The procedure for bootstrapping agentic docs in a repository with little or no agentic surface. Loaded in Phase 3 when wiring is missing.

The target layout lives in [agentic-architecture.md](agentic-architecture.md) under "Standard project wiring"; this file owns the procedure only.

A convention the repository already declares wins over every default here.

## Ground rules

- Idempotent repair: create only what is missing, never overwrite, and rerunning the scaffold on a finished repository changes nothing.
- No empty structure: create a directory, symlink, or config file only when a real asset or entry lands in it, and a prescribed `.gitignore` counts.
- No `.keep` files, no `{}` settings, and no placeholder sections.
- Repository evidence first: derive every suggestion (commands, rules, hooks, skills) from manifests, configs, and history, never from a canned list.
- Self-contained output: nothing created references the user's home, dotfiles, agent tree, user-level skills, or this skill's bundled files.
- Write budgets as numbers and name `/sync-agents --check` as the way to measure them.
- Interactive runs ask the closed questions below. Non-interactive runs apply the stated defaults, skip everything optional, and report the assumptions.
- Under `--check`, replace every creation with a precise proposal.

## Questions

Ask up to three closed questions before creating anything, batched when the tool supports it:

1. **Tools** (multi-select): Claude Code, Codex, Copilot; pre-select the tools detectable in the repository or its history, else Claude Code and Codex.
2. **Skills** (yes or no; default no): manage project skills with the skills CLI.
3. **Assets** (multi-select; default none): rules, hooks, commands; selecting one means drafting concrete repository-derived starters.

- State in the Tools question that `AGENTS.md` is universal and not optional, and that `.agents/` materializes when content lands in it.
- A non-interactive run applies each pre-selected or default answer as given.
- Create wiring only for accepted drafts.

## Actions per selection

### Always

- Create `AGENTS.md` at the root when it is missing.
- Populate only sections with real, verified content: one-line project summary, detected commands, structure, non-obvious conventions.
- Omit a section rather than write a placeholder; in an effectively empty repository, keep the file to the few facts that hold.
- Agents execute listed commands, so check each detected command runs and document a broken one as a gotcha, not as working.
- Respect the root budget in [context-budgets.md](context-budgets.md).

### Claude Code

- `CLAUDE.md` containing exactly `@AGENTS.md`.
- `.claude/.gitignore` listing the runtime entries `settings.local.json` and `worktrees/`.
- Those entries keep sessions from dirtying the repository and leave the root `.gitignore` untouched.
- `.claude/settings.json` only with real content: a permission allowlist for the detected build and test commands, or hook wiring from the assets question.

### Codex

- Nothing: Codex reads `AGENTS.md` natively.
- Add a `.codex/` route only after verifying the tool actually loads it at project scope.

### Copilot

- Nothing for the entrypoint: Copilot reads `AGENTS.md` natively.
- With accepted rules: `.github/instructions -> ../.agents/rules`.
- The legacy `.github/copilot-instructions.md -> AGENTS.md` symlink only on explicit request for pre-`AGENTS.md` Copilot surfaces.

### Skills: yes

- `.agents/skills/` with `.agents/skills/.gitignore` containing `/*/`, so installed skills stay untracked.
- Track a hand-authored skill by adding its own `!/<name>/` line.
- `.claude/skills -> ../.agents/skills` when Claude Code is selected.
- Propose skills from repository evidence, through the `find-skills` skill when available, else `npx skills search`.
- Install each accepted skill with `npx skills add <owner>/<repo> --skill <name> --yes`.
- The CLI creates and owns `skills-lock.json`; never hand-create or edit the lockfile.
- With zero accepted skills there is no lockfile until the first install.

### Assets: rules

- Draft one to three scoped rules from repository evidence: framework conventions, formatter constraints, directory contracts.
- Give each rule the frontmatter its selected tools need: `paths:` for Claude Code, `applyTo:` for Copilot.
- On acceptance: `.agents/rules/` with the accepted files, plus `.claude/rules -> ../.agents/rules`.
- When Copilot is selected, also create `.github/instructions -> ../.agents/rules`.
- When a selected tool has no glob loader (Codex), add a routing line to `AGENTS.md` naming when to read each rule.

### Assets: hooks

- Draft hooks from repository evidence, such as format-on-edit using the repository's configured formatter.
- On acceptance: `.agents/hooks/` with the executable scripts, plus `.claude/hooks -> ../.agents/hooks`.
- Add the matching `hooks` wiring inside `.claude/settings.json`.

### Assets: commands

- Draft slash commands wrapping the repository's non-trivial workflows.
- On acceptance: `.claude/commands/` with the accepted files.
- Commands are tool-specific, so they live in `.claude/`, not `.agents/`.

## Conflicts

Never migrate a working layout silently:

- A fat `CLAUDE.md` with no `AGENTS.md`: propose moving the content to `AGENTS.md` and thinning `CLAUDE.md` to the import.
- Leave both files untouched until the proposal is accepted, which overrides the Always item; a non-interactive run only reports it.
- Independent pieces, such as `.claude/.gitignore`, may still be created.
- A whole-directory `.claude -> .agents` symlink (an older convention): leave it working; flag the difference only when it causes a concrete finding.
- Existing partial wiring: fill only the gaps the selections imply.

## After scaffolding

Run the normal Phase 4 verification on everything created: link and symlink resolution, valid JSON and frontmatter, executable bits, and budgets.

Confirm with `git check-ignore` that runtime paths are ignored while tracked assets are not.
