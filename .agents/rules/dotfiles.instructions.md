---
description: 'Use when editing the $HOME dotfiles repo: shell, git, brew, git hooks, or agent config. Repo-specific conventions: the single-source-of-truth layout, the allowlist .gitignore, non-standard commit types, shell startup internals, and new-machine bootstrap.'
applyTo: '.agents/**,.codex/**,.config/git/**,.github/**,.homebrew/**,.zsh/**,.aliases,.bash_profile,.bashrc,.gitconfig,.gitignore,.install.sh,.macos,.profile,.zprofile,.zshenv,.zshrc'
paths:
  - '.agents/**'
  - '.codex/**'
  - '.config/git/**'
  - '.github/**'
  - '.homebrew/**'
  - '.zsh/**'
  - '.aliases'
  - '.bash_profile'
  - '.bashrc'
  - '.gitconfig'
  - '.gitignore'
  - '.install.sh'
  - '.macos'
  - '.profile'
  - '.zprofile'
  - '.zshenv'
  - '.zshrc'
---

# Dotfiles

These conventions apply **only** when working in the `$HOME` dotfiles git repo (branch `main`). `$HOME` itself is the repo. Editing any file under `~` may be a tracked change; treat it like a repo edit, not a throwaway.

## Portability

- Every tracked file must clone onto a fresh machine and stay shareable, so nothing here may carry a path or identifier that only resolves on this machine: no `/Users/<name>`, hostname, serial, or personal email. Write `$HOME`, `~`, `$HOMEBREW_PREFIX`, `$XDG_*`, or a repo-relative path instead, and leave identity and machine state in the untracked files that already own it (`~/.gitconfig`, `.codex/config.toml`, `.claude/statusline.json`). Standard system paths (`/bin/sh`, `/etc`, `/usr/bin/env`) are not machine-specific and stay as they are.
- Two approved literals, both load-bearing: the `/opt/homebrew` and `/usr/local` PATH pair that bootstraps a script before `$HOMEBREW_PREFIX` exists. Adding others needs the user's explicit approval.
- `pre-push` fails the push when a tracked file contains a `/Users/<name>` path.

## Single source of truth for agent config

- Edit `.agents/{AGENTS.md,rules,skills,hooks}`. The tracked links at `~/.claude/{CLAUDE.md,hooks,rules,skills}`, `~/.codex/{AGENTS.md,hooks,skills}`, and `~/.copilot/{copilot-instructions.md,instructions}` resolve to those sources. Never edit through a link or duplicate content across agents. Tool-only assets are tracked in place, not linked: `.claude/{output-styles,commands}` and `.codex/hooks.json`.
- Track portable Codex defaults in `.codex/settings.toml`, linked at `/etc/codex/config.toml`. Keep `.codex/config.toml` ignore, it's used for secrets, machine state, and complete private MCP definitions. Never track it.
- **Install skills globally with `npx skills add <owner/repo> --skill <name> --global --yes`** (the [skills.sh](https://skills.sh) CLI), run from `~`. `--global` is **required**: it writes the skill into `.agents/skills/` and pins the entry in **`.agents/.skill-lock.json`**, the single source of truth (without it the CLI writes a project-level `~/skills-lock.json`, which must not exist here). Drop `--skill <name>` to install every skill in the collection. The skills themselves are gitignored (`.agents/skills/.gitignore` is allowlist-style: `/*/` then `!`-unignore the few tracked ones); the tracked `.agents/.skill-lock.json` is what git carries. Update every global skill with `npx skills update --global --yes`. Never hand-copy a skill folder or hand-edit the lockfile; let the CLI write both.
- **One source, one route per tool, no duplication.** `.agents/rules/*.instructions.md` is the single rule source, and every scoped file carries matching `paths` (Claude) and `applyTo` (Copilot) frontmatter plus a current, non-empty description. Claude Code consumes `.claude/rules` natively: files without `paths:` are always on, while scoped files load when a touched path matches. Codex loads `.codex/AGENTS.md` and must open relevant rule files by intent because it has no `paths` or `applyTo` loader. Copilot hardcodes both of its home paths with no setting to move them, so those two links are required; never restore `~/.github/instructions` or `~/.github/copilot-instructions.md`, which made Copilot load every rule twice inside `$HOME`.
- **VS Code: only the `false` entries in `chat.instructionsFilesLocations` carry weight.** `.github/instructions`, `.claude/rules`, `~/.copilot/instructions`, and `~/.claude/rules` are built-in roots, on unless disabled, so the machine-wide rules reach every project with no user setting and a `true` entry for one is a no-op. `.vscode/user/settings.json` therefore carries only the two Claude-root disables that stop those rules loading twice. Inside `$HOME` several roots collide on one physical `.agents/rules`, and VS Code deduplicates symlinked `AGENTS.md`, `CLAUDE.md`, and `copilot-instructions.md` by real path but never `*.instructions.md`, so `.vscode/settings.json` names `.agents/rules` and turns off every other root along with `chat.useAgentsMdFile` and `chat.useClaudeMdFile`.
- `.agents/hooks/` holds shared Claude Code and Codex hooks (not git hooks): `guard-managed-files.sh` blocks writes to generated or symlinked managed files, `guard-committed-writing.sh` blocks edits that add an em/en dash or a `/Users/<name>` path to a non-gitignored file in any git work tree (write-time twin of the `pre-push` portability check), and `format-edited-file.sh` runs the repo's declared formatter after edits. Claude Code wires them in `.claude/settings.json`; Codex wires them in the tracked `.codex/hooks.json`. Both tools reach the scripts through relative `hooks` symlinks. Keep each hook's behavior documented in its header comment and executable (`chmod +x`). Distinct from the git hooks in `.config/git/hooks/` covered below.
- Statusline scripts are self-contained entrypoints wired in `.claude/settings.json`: `.claude/statusline.sh` renders the main statusline, and `.claude/subagent-statusline.sh` renders one compact line per background task (label, context bar, percent, tokens). `statusline.sh` reads every setting (`theme`, `layout`, and the `bar`, `effort`, `context` objects) from `.claude/statusline.json`, `$CLAUDE_STATUSLINE_CONFIG` is the only env var it reads and points at an alternate config file. The script's header comment is the single reference for valid values, defaults, and layout segments: update it with every behavior change. `.claude/statusline.schema.json` mirrors the header and is referenced by a relative `$schema` in the config; keep schema and header in step. `/statusline-config` shows, validates and sets any key, reading the valid values, defaults and descriptions out of the schema, so adding a setting means editing the script, its header and the schema, never the command. Keep both scripts bash 3.2 compatible (no associative arrays, expand possibly-empty arrays as `${arr[@]+"${arr[@]}"}`); error mode follows the shell rule. Both entrypoints are allowlisted and must be `chmod +x`.

## Generated files

- The machine-wide generated-files rule (AGENTS.md) applies here, but artifacts always go in **`~/.agents/artifacts/`, for every agent**, never a per-agent `.claude/` or `.codex/` folder. No `.gitignore` change needed: the allowlist below leaves it untracked.

## Allowlist `.gitignore`

- `.gitignore` is an allowlist (`/*` then `!`-unignores). **A new file under `~` is NOT tracked unless you add a matching `!` rule to `.gitignore` in the same change.**

## Commit conventions (this repo only)

- Enforced by commitlint via the `commit-msg` hook in `.config/git/hooks`, re-checked on `pre-push` (which also runs `shellcheck` and `shfmt -d` on the shell dotfiles and `oxfmt --check`). Every message must pass `.commitlintrc`: `<type>(<scope>)?: <subject>`: type + subject required, lower-case, no empty subject.
- **Allowed types (non-standard):** `agents`, `brew`, `chore`, `docs`, `editor`, `git`, `node`, `python`, `ruby`, `shell`. Allowed scopes (optional): `cask`, `formula`, `mas` (under `brew`), `vscode` and `zed` (under `editor`), `npm` (under `node`), `claude`, `codex`, `copilot` (under `agents`, only when a change is bound to one tool's non-shared config), `shell` and `zsh` (under `shell`). Do **NOT** use `feat`/`fix`/`refactor` here.
- **Agent config** (`.agents/**`, `AGENTS.md`, the rules/skills/hooks, and the `.claude`/`.codex`/`.copilot` symlinks) → commit with type `agents`.
- **Editor config** → commit with type `editor`: VS Code (`.vscode/**`) under scope `vscode`, Zed (`.config/zed/**` and `.zed/**`) under scope `zed`. Zed reads `~/.config/zed/` directly, so its tracked files ARE the live config (no symlink or `dotfiles init` as VS Code's `settings.json`).
- **VS Code extensions**: `dotfiles init` installs any id listed in the `.vscode/extensions.json` recommendations that has no folder in `~/.vscode/extensions` (cheap glob check, `code --install-extension` only when something is missing). Keep the recommendations list as the single wanted-set; only add marketplace-published ids, since unpublished ones fail the install with a warning on every new machine.

## Launch agents

- Every `.config/launchd/*.plist` is a tracked template written with literal `$HOME` and `$HOMEBREW_PREFIX`. `dotfiles init` renders them all into `~/Library/LaunchAgents/` and reloads whatever changed; `dotfiles doctor` reports drift. Edit the template, never the generated file. Init never deletes anything, since a generated agent is indistinguishable from a third-party one, so retiring an agent means `launchctl bootout gui/$UID/<label>` and removing the generated plist by hand.
- The filename stem is the `Label`, so `claude-rc.plist` must declare `claude-rc`.
- `Disabled` is the on/off switch, so active agents carry `<false/>`. Setting it to `<true/>` makes the next `dotfiles init` unload the agent and delete its generated plist, which is safe because the template names the file. Never set it through `launchctl enable/disable`: launchd keeps that state externally and it silently outranks the template.
- launchd expands nothing at runtime, so every path in a rendered plist must be absolute: a `~` or a bare binary name both fail with `EX_CONFIG` (78). Never set `ProcessType` to `Background`, which pins the job and all its children to efficiency cores (~3.5x slower); omit the key.

## Shell startup & internals

- Startup order: `.zshenv` (env, PATH; put new env/PATH here) → `.zprofile` (**GENERATED** by the `profile` plugin, never hand-edit) → `.zshrc` (oh-my-zsh, plugins, completions, then `dotfiles init` to self-heal machine-local state) → `.aliases`.
- Plugins share one leveled logger: `_zsh::log <error|warn|success|info> <plugin> <text>` from the `logger` plugin (loaded first), colored to stderr on a TTY, plain `plugin: level: text` when piped. Each consumer carries a 2-line fallback (`(( $+functions[_zsh::log] )) || _zsh::log() { ... }`) so it still works cloned standalone. Emit diagnostics through it, not raw `print`/`echo`.
- Git hooks are native (no husky, no global `core.hooksPath` or `init.templateDir`). The `~` repo uses a repo-local `core.hooksPath` of `.config/git/hooks` (commitlint on `commit-msg`; commitlint + shellcheck + shfmt + oxfmt on `pre-push`), re-asserted by `dotfiles init`. Edit hooks there, not in `.git/hooks/`.
- Git config splits by tracking, with no include chain: the tracked `.config/git/config` (XDG global scope, read first) carries every shared setting; the untracked root `~/.gitconfig` (read second, so its values win) carries identity and machine-local state (`user.*`, signing key, 1Password `gpg.ssh.program`, `core.editor`, per-client overrides). Never write an email, key, or machine path into `.config/git/config`.
- Brewfile is at `.homebrew/Brewfile`.
- npm globals are tracked by the `npm-global` plugin: the `npm` wrapper re-dumps `.npm/package.json` (synchronously, offline) after every mutating global command (`npm dump` syncs, `npm fresh` updates then syncs, bare `npm i -g` reinstalls the manifest), and the `.config/nodenv/hooks/install/npm-global.bash` hook installs the manifest into every new Node version. Node tooling (including commitlint via `@commitlint/cli`, oxfmt, typescript, typescript-language-server) lives in the npm manifest, never in the Brewfile: its formulas drag in a duplicate Homebrew node runtime. Shell tooling (shellcheck, shfmt) still comes from the Brewfile, and `pnpm` from Corepack via its own install hook; never install those with npm.
