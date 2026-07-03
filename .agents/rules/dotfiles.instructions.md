---
description: 'Use when editing the $HOME dotfiles repo: shell, git, brew, git hooks, or agent config. Repo-specific conventions: the single-source-of-truth layout, the allowlist .gitignore, non-standard commit types, shell startup internals, and new-machine bootstrap.'
applyTo: '.agents/**,.config/git/**,.github/**,.homebrew/**,.zsh/**,.aliases,.bash_profile,.bashrc,.gitconfig,.macos,.profile,.zprofile,.zshenv,.zshrc'
paths:
  - '.agents/**'
  - '.config/git/**'
  - '.github/**'
  - '.homebrew/**'
  - '.zsh/**'
  - '.aliases'
  - '.bash_profile'
  - '.bashrc'
  - '.gitconfig'
  - '.macos'
  - '.profile'
  - '.zprofile'
  - '.zshenv'
  - '.zshrc'
---

# Dotfiles

These conventions apply **only** when working in the `$HOME` dotfiles git repo (branch `main`). `$HOME` itself is the repo. Editing any file under `~` may be a tracked change; treat it like a repo edit, not a throwaway.

## Single source of truth for agent config

- Edit `.agents/{AGENTS.md,rules,skills,hooks,output-styles}`. `~/.claude/*`, `~/.codex/{AGENTS.md,skills}`, `~/.copilot/instructions`, and `~/.github/*` resolve to `.agents` via tracked symlinks. Never edit symlink targets directly or duplicate content across agents. Both `~/.claude/skills` and `~/.codex/skills` point at `.agents/skills`, so Claude and Codex share one skill set. `~/.claude/output-styles` points at `.agents/output-styles` (a Claude Code feature; no Codex equivalent).
- **Install skills globally with `npx skills add <owner/repo> --skill <name> --global --yes`** (the [skills.sh](https://skills.sh) CLI), run from `~`. `--global` is **required**: it writes the skill into `.agents/skills/` and pins the entry in **`.agents/.skill-lock.json`**, the single source of truth (without it the CLI writes a project-level `~/skills-lock.json`, which must not exist here). Drop `--skill <name>` to install every skill in the collection. The skills themselves are gitignored (`.agents/skills/.gitignore` is allowlist-style: `/*/` then `!`-unignore the few tracked ones); the tracked `.agents/.skill-lock.json` is what git carries. Update every global skill with `npx skills update --global --yes`. Never hand-copy a skill folder or hand-edit the lockfile; let the CLI write both.
- **One source, one route per tool, no duplication.** `.agents/rules/*.instructions.md` is the single rule source. `~/.claude/rules`, `~/.github/instructions`, and `~/.copilot/instructions` are all symlinks to it, so the same physical files are reachable many ways. Each tool consumes them through exactly **one** location. The wiring: **Claude Code** reads `.claude/rules` natively (any `.md`; always-on without `paths:` frontmatter, else loaded when a touched file matches the globs); **Codex** reads only the always-on `~/.codex/AGENTS.md` and opens the relevant rule file by hand (it has no glob/`applyTo` mechanism); **Copilot** reads `.github/instructions` (honors `applyTo`). Each scoped rule file therefore carries **both** `applyTo` (Copilot) and `paths` (Claude) frontmatter pointing at the same globs; each tool reads its own key and ignores the other. Keep the `description` frontmatter current and non-empty on every rule; it states the trigger, and Copilot skips a file without it.
- **VS Code `chat.instructionsFilesLocations`: disable every default root except `.github/instructions`.** VS Code has **four** hardcoded default `*.instructions.md` source folders, all enabled until set `false`: `.github/instructions`, `.claude/rules`, `~/.copilot/instructions`, `~/.claude/rules`. Because `$HOME` is the workspace, the two `~/`-prefixed user-profile roots resolve onto the home dir and re-find the same `.agents/rules` symlinks, so naming only `.claude/rules` leaves them active and the Customizations panel still shows three rows. Keep this exact block in `.vscode/user/settings.json` so only one root scans the dir:
  ```jsonc
  "chat.instructionsFilesLocations": {
    ".github/instructions": true,
    ".claude/rules": false,
    "~/.claude/rules": false,
    "~/.copilot/instructions": false
  }
  ```
- `.agents/hooks/` holds **Claude Code** hooks (not git hooks), wired in `.claude/settings.json` and reached via the `~/.claude/hooks` symlink: `guard-managed-files.sh` (PreToolUse, blocks writes to generated/symlinked managed files) and `format-edited-file.sh` (PostToolUse, runs the repo's declared formatter on the edited file). Keep each hook's behavior documented in its header comment and executable (`chmod +x`). Distinct from the git hooks in `.config/git/hooks/` covered below.

## Generated files

- The machine-wide generated-files rule (AGENTS.md) applies here, but artifacts always go in **`~/.agents/artifacts/`, for every agent**, never a per-agent `.claude/` or `.codex/` folder. No `.gitignore` change needed: the allowlist below leaves it untracked.

## Allowlist `.gitignore`

- `.gitignore` is an allowlist (`/*` then `!`-unignores). **A new file under `~` is NOT tracked unless you add a matching `!` rule to `.gitignore` in the same change.**

## Commit conventions (this repo only)

- Enforced by commitlint via the `commit-msg` hook in `.config/git/hooks`, re-checked on `pre-push` (which also runs `shellcheck` and `shfmt -d` on the shell dotfiles and `oxfmt --check`). Every message must pass `.commitlintrc`: `<type>(<scope>)?: <subject>`: type + subject required, lower-case, no empty subject.
- **Allowed types (non-standard):** `agents`, `brew`, `chore`, `docs`, `editor`, `git`, `node`, `python`, `ruby`, `shell`. Allowed scopes (optional): `cask`, `formula`, `mas` (under `brew`), `vscode` (under `editor`), `npm` (under `node`), `claude`, `codex`, `copilot` (under `agents`, only when a change is bound to one tool's non-shared config), `shell` and `zsh` (under `shell`). Do **NOT** use `feat`/`fix`/`refactor` here.
- **Agent config** (`.agents/**`, `AGENTS.md`, the rules/skills/hooks, and the `.claude`/`.codex`/`.copilot`/`.github` symlinks) → commit with type `agents`.
- **VS Code config** (`.vscode/**`) → commit with type `editor`. VS Code Copilot/GitLens emit standard `feat:`/`fix:` style. That's for **other** repos, not this one.

## Shell startup & internals

- Startup order: `.zshenv` (env, PATH; put new env/PATH here) → `.zprofile` (**GENERATED** by the `profile` plugin, never hand-edit) → `.zshrc` (oh-my-zsh, plugins, completions, then `dotfiles init` to self-heal machine-local state) → `.aliases`.
- Git hooks are native (no husky, no global `core.hooksPath` or `init.templateDir`). The `~` repo uses a repo-local `core.hooksPath` of `.config/git/hooks` (commitlint on `commit-msg`; commitlint + shellcheck + shfmt + oxfmt on `pre-push`), re-asserted by `dotfiles init`. Edit hooks there, not in `.git/hooks/`.
- Brewfile is at `.homebrew/Brewfile`.
- No npm globals: command-line Node tooling (commitlint, oxfmt, shellcheck, shfmt) comes from the Brewfile, and `pnpm` comes from Corepack via a tracked nodenv install hook. Don't hand-install these as globals or reintroduce an npm-global wrapper.
