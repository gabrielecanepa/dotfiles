---
description: 'Use when editing the $HOME dotfiles repo — shell, git, brew, husky, or agent config. Repo-specific conventions: the single-source-of-truth layout, the allowlist .gitignore, non-standard commit types, shell startup internals, and new-machine bootstrap.'
applyTo: '.agents/**,.github/**,.homebrew/**,.husky/**,.zsh/**,.aliases,.bash_profile,.bashrc,.gitconfig,.macos,.profile,.zprofile,.zshenv,.zshrc'
paths:
  - '.agents/**'
  - '.github/**'
  - '.homebrew/**'
  - '.husky/**'
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

These conventions apply **only** when working in the `$HOME` dotfiles git repo (branch `main`). `$HOME` itself is the repo — editing any file under `~` may be a tracked change; treat it like a repo edit, not a throwaway.

## Single source of truth for agent config

- Edit `.agents/{AGENTS.md,rules,skills,hooks}`. `~/.claude/*`, `~/.codex/AGENTS.md`, `~/.copilot/instructions`, and `~/.github/*` resolve to `.agents` via tracked symlinks — never edit symlink targets directly or duplicate content across agents.

## Allowlist `.gitignore`

- `.gitignore` is an allowlist (`/*` then `!`-unignores). **A new file under `~` is NOT tracked unless you add a matching `!` rule to `.gitignore` in the same change.**

## Commit conventions (this repo only)

- Enforced by commitlint via husky `commit-msg`, re-checked on `pre-push` (which also runs `shellcheck` on shell dotfiles and `oxfmt --check`). Every message must pass `.commitlintrc`: `<type>(<scope>)?: <subject>` — type + subject required, lower-case, no empty subject.
- **Allowed types (non-standard):** `brew`, `chore`, `docs`, `git`, `node`, `python`, `ruby`, `shell`, `vscode`. Only allowed scope: `npm`. Do **NOT** use `feat`/`fix`/`refactor` here.
- **Agent config** (`.agents/**`, `AGENTS.md`, the rules/skills/hooks, and the `.claude`/`.codex`/`.copilot`/`.github` symlinks) → commit with type `docs`.
- VS Code Copilot/GitLens emit standard `feat:`/`fix:` style — that's for **other** repos, not this one.

## Shell startup & internals

- Startup order: `.zshenv` (env, Homebrew + `*ENV_ROOT` vars, PATH via `_init_path`) → `.zprofile` (**GENERATED** by the `profile` plugin; identity vars only — never hand-edit) → `.zshrc` (oh-my-zsh, plugins, completions) → `.aliases`. Put new env/PATH in `.zshenv`.
- `.zshrc` auto-symlinks `.husky/*` hooks into `.git/hooks/` on shell start when `profile check` passes — do not hand-edit `.git/hooks/`.
- Brewfile is at `.homebrew/Brewfile`.

## New-machine bootstrap

- `.github/install.sh` shallow-clones the repo over HTTPS into an auto-cleaned temp dir and installs each tracked file into `~`, prompting before overwriting an existing one. Replaced files are backed up (path-mirrored) to `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backup/<timestamp>/` — restore one by copying it back.
- After the script, `~` is not yet a git repo; initialize it with `git -C ~ init -b main && git -C ~ remote add origin git@github.com:gabrielecanepa/dotfiles.git && git -C ~ fetch --depth 1 origin main && git -C ~ reset --hard FETCH_HEAD` (see README §Git).
