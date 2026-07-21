# Project scaffold

The procedure for bootstrapping agentic docs in a repository with little or no
agentic surface. Loaded in Phase 3 when wiring is missing. The target layout is
defined in [agentic-architecture.md](agentic-architecture.md) under "Standard
project wiring"; this file owns the procedure only. A convention the repository
already declares wins over every default here.

## Ground rules

- Idempotent repair: create only what is missing, never overwrite, and
  rerunning the scaffold on a finished repository changes nothing.
- No empty structure: a directory, symlink, or config file is created only when
  at least one real asset or entry lands in it (a prescribed `.gitignore`
  counts). No `.keep` files, no `{}` settings, no placeholder sections.
- Repository evidence first: derive every suggestion (commands, rules, hooks,
  skills) from the repository's manifests, configs, and history, never from a
  canned list.
- Interactive runs ask the closed questions below. Non-interactive runs apply
  the stated defaults, skip everything optional, and report the assumptions.
- Under `--check`, replace every creation with a precise proposal.

## Questions

Ask up to three closed questions before creating anything, batched when the
tool supports it:

1. **Tools** (multi-select): Claude Code, Codex, Copilot. Pre-select, and in a
   non-interactive run apply as the answer, the tools already detectable in the
   repository or its history, else Claude Code and Codex. State in the question
   that `AGENTS.md` is universal and not optional; the `.agents/` tree
   materializes when content lands in it.
2. **Skills** (yes or no; default no): manage project skills with the skills
   CLI.
3. **Assets** (multi-select; default none): rules, hooks, commands. Selecting
   one means the agent drafts concrete repository-derived starters; wiring is
   created only for accepted drafts.

## Actions per selection

### Always

- `AGENTS.md` at the root when missing. Populate only sections with real,
  verified content: one-line project summary, detected commands, structure,
  non-obvious conventions. Omit a section rather than write a placeholder, and
  in an effectively empty repository keep the file to the few facts that hold.
  Listed commands get executed by agents, so check each detected command can
  run and document a currently broken one as a gotcha, not as working. Respect
  the root budget in [context-budgets.md](context-budgets.md).

### Claude Code

- `CLAUDE.md` containing exactly `@AGENTS.md`.
- `.claude/.gitignore` listing the runtime entries `settings.local.json` and
  `worktrees/`, so sessions never dirty the repository and the root
  `.gitignore` stays untouched.
- `.claude/settings.json` only when there is real content for it, such as a
  permission allowlist for the detected build and test commands, or hook
  wiring from the assets question.

### Codex

- Nothing. Codex reads `AGENTS.md` natively. Add a `.codex/` route only after
  verifying the tool actually loads it at project scope.

### Copilot

- Nothing for the entrypoint: Copilot reads `AGENTS.md` natively.
- With accepted rules: `.github/instructions -> ../.agents/rules`.
- The legacy `.github/copilot-instructions.md -> AGENTS.md` symlink only on
  explicit request for pre-`AGENTS.md` Copilot surfaces.

### Skills: yes

- `.agents/skills/` with `.agents/skills/.gitignore` containing `/*/`, so
  installed skills stay untracked and a hand-authored skill is tracked by
  adding its own `!/<name>/` line.
- `.claude/skills -> ../.agents/skills` when Claude Code is selected.
- Propose skills from repository evidence, through the `find-skills` skill
  when available, else `npx skills search`. Install each accepted skill with
  `npx skills add <owner>/<repo> --skill <name> --yes`; the CLI creates and
  owns `skills-lock.json`. Never hand-create or edit the lockfile: with zero
  accepted skills there is no lockfile until the first install.

### Assets: rules

- Draft one to three scoped rules from repository evidence (framework
  conventions, formatter constraints, directory contracts), with the
  frontmatter each selected tool needs: `paths:` for Claude Code, `applyTo:`
  for Copilot.
- On acceptance: `.agents/rules/` with the accepted files, plus
  `.claude/rules -> ../.agents/rules` and, when Copilot is selected,
  `.github/instructions -> ../.agents/rules`.
- When a selected tool has no glob loader (Codex), add a short routing line to
  `AGENTS.md` naming when to read each rule, so no rule is unreachable for
  that tool.

### Assets: hooks

- Draft hooks from repository evidence, for example format-on-edit using the
  repository's configured formatter. On acceptance: `.agents/hooks/` with the
  executable scripts, `.claude/hooks -> ../.agents/hooks`, and the matching
  `hooks` wiring inside `.claude/settings.json`.

### Assets: commands

- Draft slash commands wrapping the repository's non-trivial workflows. On
  acceptance: `.claude/commands/` with the accepted files. Commands are
  tool-specific, so they live in `.claude/`, not `.agents/`.

## Conflicts

Never migrate a working layout silently:

- A fat `CLAUDE.md` with no `AGENTS.md`: propose moving the content to
  `AGENTS.md` and thinning `CLAUDE.md` to the import. Leave both files
  untouched until the proposal is accepted; this overrides the Always item,
  and a non-interactive run only reports the proposal. Independent pieces,
  such as `.claude/.gitignore`, may still be created.
- A whole-directory `.claude -> .agents` symlink (an older convention): leave
  it working; flag the difference only when it causes a concrete finding.
- Existing partial wiring: fill only the gaps the selections imply.

## After scaffolding

Run the normal Phase 4 verification on everything created: link and symlink
resolution, valid JSON and frontmatter, executable bits, budgets, and
`git check-ignore` confirming runtime paths are ignored while tracked assets
are not.
