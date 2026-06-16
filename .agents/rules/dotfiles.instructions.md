---
description: 'Use when editing the $HOME dotfiles repo — shell, git, brew, git hooks, or agent config. Repo-specific conventions: the single-source-of-truth layout, the allowlist .gitignore, non-standard commit types, shell startup internals, and new-machine bootstrap.'
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

These conventions apply **only** when working in the `$HOME` dotfiles git repo (branch `main`). `$HOME` itself is the repo — editing any file under `~` may be a tracked change; treat it like a repo edit, not a throwaway.

## Single source of truth for agent config

- Edit `.agents/{AGENTS.md,rules,skills,hooks}`. `~/.claude/*`, `~/.codex/AGENTS.md`, `~/.copilot/instructions`, and `~/.github/*` resolve to `.agents` via tracked symlinks — never edit symlink targets directly or duplicate content across agents.

## Allowlist `.gitignore`

- `.gitignore` is an allowlist (`/*` then `!`-unignores). **A new file under `~` is NOT tracked unless you add a matching `!` rule to `.gitignore` in the same change.**

## Commit conventions (this repo only)

- Enforced by commitlint via the `commit-msg` hook in `.config/git/local`, re-checked on `pre-push` (which also runs `shellcheck` on shell dotfiles and `oxfmt --check`). Every message must pass `.commitlintrc`: `<type>(<scope>)?: <subject>` — type + subject required, lower-case, no empty subject.
- **Allowed types (non-standard):** `agents`, `brew`, `chore`, `docs`, `editor`, `git`, `node`, `python`, `ruby`, `shell`. Allowed scopes: `npm`, `zsh`. Do **NOT** use `feat`/`fix`/`refactor` here.
- **Agent config** (`.agents/**`, `AGENTS.md`, the rules/skills/hooks, and the `.claude`/`.codex`/`.copilot`/`.github` symlinks) → commit with type `agents`.
- **VS Code config** (`.vscode/**`) → commit with type `editor`. VS Code Copilot/GitLens emit standard `feat:`/`fix:` style — that's for **other** repos, not this one.

## Shell startup & internals

- Startup order: `.zshenv` (env, Homebrew + `*ENV_ROOT` vars, PATH defined by `initialize_path`) → `.zprofile` (**GENERATED** by the `profile` plugin; identity vars only — never hand-edit) → `.zshrc` (oh-my-zsh, plugins, calls `initialize_path` then unsets it, completions) → `.aliases`. Put new env/PATH in `.zshenv`.
- Git hooks are native (no husky). The global `.gitconfig` sets `core.hooksPath` to `.config/git/hooks` (repo-wide hooks, e.g. sweep gone branches), and `.zshrc` sets a repo-local `core.hooksPath` of `.config/git/local` on `~` when `profile check` passes (commitlint, shellcheck, oxfmt). Edit hooks in `.config/git/`, not `.git/hooks/`.
- Brewfile is at `.homebrew/Brewfile`.

## New-machine bootstrap

- `.github/install.sh` shallow-clones the repo over HTTPS into an auto-cleaned temp dir and installs each tracked file into `~`, prompting before overwriting an existing one. Replaced files are backed up (path-mirrored) to `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backup/<timestamp>/` — restore one by copying it back.
- After the script, `~` is not yet a git repo; initialize it with `git -C ~ init -b main && git -C ~ remote add origin git@github.com:gabrielecanepa/dotfiles.git && git -C ~ fetch --depth 1 origin main && git -C ~ reset --hard FETCH_HEAD` (see README §Git).
