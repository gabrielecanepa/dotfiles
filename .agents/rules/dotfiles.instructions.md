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

- Edit `.agents/{AGENTS.md,rules,skills,hooks,output-styles}`. `~/.claude/*`, `~/.codex/AGENTS.md`, `~/.codex/skills`, `~/.copilot/instructions`, and `~/.github/*` resolve to `.agents` via tracked symlinks. Never edit symlink targets directly or duplicate content across agents. Both `~/.claude/skills` and `~/.codex/skills` point at `.agents/skills`, so Claude and Codex share one skill set. `~/.claude/output-styles` points at `.agents/output-styles` (a Claude Code feature; no Codex equivalent).
- **One source, one route per tool, no duplication.** `.agents/rules/*.instructions.md` is the single rule source. `~/.claude/rules`, `~/.github/instructions`, and `~/.copilot/instructions` are all symlinks to it, so the same physical files are reachable many ways. Each tool consumes them through exactly **one** location. The wiring: **Claude Code** reads `.claude/rules` natively (any `.md`; honors the `paths:` frontmatter); **Codex** reads only the always-on `~/.codex/AGENTS.md` and opens the relevant rule file by hand (it has no glob/`applyTo` mechanism); **Copilot** reads `.github/instructions` (honors `applyTo`). Each scoped rule file therefore carries **both** `applyTo` (Copilot) and `paths` (Claude) frontmatter pointing at the same globs; each tool reads its own key and ignores the other. Keep a non-empty `description` on every file or Copilot skips it.
- **VS Code `chat.instructionsFilesLocations`: disable every default root except `.github/instructions`.** VS Code has **four** hardcoded default `*.instructions.md` source folders, all enabled until set `false`: `.github/instructions`, `.claude/rules`, `~/.copilot/instructions`, `~/.claude/rules`. Because `$HOME` is the workspace, the two `~/`-prefixed user-profile roots resolve onto the home dir and re-find the same `.agents/rules` symlinks, so naming only `.claude/rules` leaves them active and the Customizations panel still shows three rows. Keep this exact block in `.vscode/user/settings.json` so only one root scans the dir:
  ```jsonc
  "chat.instructionsFilesLocations": {
    ".github/instructions": true,
    ".claude/rules": false,
    "~/.claude/rules": false,
    "~/.copilot/instructions": false
  }
  ```
- `.agents/hooks/` holds **Claude Code** hooks (not git hooks), wired in `.claude/settings.json` and reached via the `~/.claude/hooks` symlink: `guard-managed-files.sh` (PreToolUse, blocks writes to generated/symlinked managed files). Keep its behavior documented in the header comment of the script. Distinct from the git hooks in `.config/git/hooks/` covered below.

## Generated files (artifacts vs tmp)

- The machine-wide artifacts/tmp rule (AGENTS.md) applies here, but the location is **always `~/.agents/artifacts/` and `~/.agents/tmp/<session-id>/`, for every agent**, never a per-agent `.claude/` or `.codex/` folder.
- No `.gitignore` change needed: the allowlist below leaves both untracked. Still delete `~/.agents/tmp/<session-id>/` at the end of the session.

## Allowlist `.gitignore`

- `.gitignore` is an allowlist (`/*` then `!`-unignores). **A new file under `~` is NOT tracked unless you add a matching `!` rule to `.gitignore` in the same change.**

## Commit conventions (this repo only)

- Enforced by commitlint via the `commit-msg` hook in `.config/git/hooks`, re-checked on `pre-push` (which also runs `shellcheck` and `shfmt -d` on the shell dotfiles and `oxfmt --check`). Every message must pass `.commitlintrc`: `<type>(<scope>)?: <subject>`: type + subject required, lower-case, no empty subject.
- **Allowed types (non-standard):** `agents`, `brew`, `chore`, `docs`, `editor`, `git`, `node`, `python`, `ruby`, `shell`. Allowed scopes (optional): `cask`, `formula`, `mas` (under `brew`), `vscode` (under `editor`), `npm` (under `node`), `claude`, `codex`, `copilot` (under `agents`, only when a change is bound to one tool's non-shared config), `shell` and `zsh` (under `shell`). Do **NOT** use `feat`/`fix`/`refactor` here.
- **Agent config** (`.agents/**`, `AGENTS.md`, the rules/skills/hooks, and the `.claude`/`.codex`/`.copilot`/`.github` symlinks) → commit with type `agents`.
- **VS Code config** (`.vscode/**`) → commit with type `editor`. VS Code Copilot/GitLens emit standard `feat:`/`fix:` style. That's for **other** repos, not this one.

## Shell startup & internals

- Startup order: `.zshenv` (env, Homebrew + `*ENV_ROOT` vars, PATH defined by `initialize_path`) → `.zprofile` (**GENERATED** by the `profile` plugin; identity vars only, never hand-edit) → `.zshrc` (oh-my-zsh, plugins, re-runs `initialize_path` then unsets it, completions, then `dotfiles init` to self-heal machine-local state) → `.aliases`. Put new env/PATH in `.zshenv`.
- Git hooks are native (no husky). There is **no** global `core.hooksPath` or `init.templateDir`, so per-repo hook managers (lefthook, etc.) own each repo's `.git/hooks` unimpeded; nothing is imposed machine-wide. The `~` dotfiles repo gets its own checks via a repo-local `core.hooksPath` of `.config/git/hooks`, re-asserted on startup by `dotfiles init` (commitlint on `commit-msg`; commitlint + shellcheck + shfmt + oxfmt on `pre-push`). The `dotfiles` plugin (`init` to fix drift, `doctor` to report it) also re-links the VS Code settings symlink that Code clobbers on update. Edit those hooks in `.config/git/hooks/`, not `.git/hooks/`.
- Brewfile is at `.homebrew/Brewfile`.
- No npm globals: command-line Node tooling (commitlint, oxfmt, shellcheck, shfmt) is installed via the Brewfile, and `pnpm` comes from Corepack, not a global install. A tracked nodenv install hook at `.config/nodenv/hooks/install/corepack.bash` (wired via `NODENV_HOOK_PATH` in `.zshenv`) runs `corepack enable` after every `nodenv install`, so pnpm follows the active Node version. Don't hand-install these as globals or reintroduce an npm-global wrapper.

## New-machine bootstrap

- `.github/install.sh` shallow-clones the repo over HTTPS into an auto-cleaned temp dir and installs each tracked file into `~`, prompting before overwriting an existing one. Replaced files are backed up (path-mirrored) to `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backup/<timestamp>/`. Restore one by copying it back.
- After the script, `~` is not yet a git repo; initialize it with `git -C ~ init -b main && git -C ~ remote add origin git@github.com:gabrielecanepa/dotfiles.git && git -C ~ fetch --depth 1 origin main && git -C ~ reset --hard FETCH_HEAD` (see README §Git).
