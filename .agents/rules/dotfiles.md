---
description: 'Use only in the $HOME dotfiles repository: portability, allowlist tracking, and the commit convention; routes agent config, shell internals, and launch agents to companion rules.'
applyTo: '.agents/**,.claude/**,.codex/**,.config/**,.copilot/**,.github/**,.homebrew/**,.local/**,.npm/**,.vscode/**,.zed/**,.zsh/**,Library/**,.CFUserTextEncoding,.aliases,.bash_profile,.bashrc,.commitlintrc.json,.editorconfig,.gemrc,.gitconfig,.gitignore,.hushlogin,.install.sh,.irbrc,.npmrc,.oxfmtrc.json,.profile,.rubocop.yml,.shellcheckrc,.vimrc,.zprofile,.zshenv,.zshrc'
paths:
  - '.agents/**'
  - '.claude/**'
  - '.codex/**'
  - '.config/**'
  - '.copilot/**'
  - '.github/**'
  - '.homebrew/**'
  - '.npm/**'
  - '.vscode/**'
  - '.zed/**'
  - '.zsh/**'
  - 'Library/**'
  - '.CFUserTextEncoding'
  - '.aliases'
  - '.bash_profile'
  - '.bashrc'
  - '.commitlintrc.json'
  - '.editorconfig'
  - '.gemrc'
  - '.gitconfig'
  - '.gitignore'
  - '.hushlogin'
  - '.install.sh'
  - '.irbrc'
  - '.npmrc'
  - '.oxfmtrc.json'
  - '.profile'
  - '.rubocop.yml'
  - '.shellcheckrc'
  - '.vimrc'
  - '.zprofile'
  - '.zshenv'
  - '.zshrc'
---

# Dotfiles repository

These rules apply only when `$HOME` is the active repository. Treat every file under `~` as potentially tracked and preserve unrelated work.

## Portability

- Every tracked file must work on a fresh machine: use `$HOME`, `~`, `$HOMEBREW_PREFIX`, `$XDG_*`, or a repository-relative path.
- Never write a user path, hostname, serial, personal email, or other machine identity into a tracked file; identity stays in its ignored owners.
- The `/opt/homebrew` and `/usr/local` PATH pair is the only approved machine-location exception, because bootstrap runs before `$HOMEBREW_PREFIX` exists.
- Standard system paths such as `/bin/sh`, `/etc`, `/Users/Shared`, and `/usr/bin/env` are portable; any other exception requires explicit approval.
- The writing hook and `pre-push` reject committed user paths; the managed-file hook blocks edits through linked or generated routes.
- Outside `$HOME`, the writing hook also rejects `~`-anchored references to the agent tree or `~/Developer`, so a project file never depends on these dotfiles.

## Tracking

- `.gitignore` is an allowlist that starts with `/*`; add a matching `!` rule with every new tracked path.
- Track a machine file with fixed content in place, never generated or linked: `.hushlogin` and `.CFUserTextEncoding`.
- Plain-text files under `~/Library` follow the same rule: `KeyBindings/DefaultKeyBinding.dict`, the VS Code user files, and the launch agents.

## Commit convention

- `.commitlintrc.json` and the `commit-msg` hook enforce an allowlisted lower-case type, an optional allowlisted scope, and a subject with no trailing period.
- Leave a blank line before any body and keep the subject lower-case.
- Allowed types: `agents`, `brew`, `chore`, `docs`, `git`, `gui`, `node`, `python`, `ruby`, `shell`, `tui`. Never use `feat`, `fix`, or `refactor`.
- Scopes by type: `agents` uses `claude`, `codex`, `copilot`, or `opencode`; `brew` uses `cask` or `mas`; `gui` uses `ghostty`, `vscode`, or `zed`.
- More scopes: `node` uses `npm`; `shell` uses `bash`, `sh`, or `zsh`; `tui` uses `neovim`.
- `gui` covers native GUI applications; `tui` covers terminal-UI applications such as Neovim.
- Use `agents` for shared agent configuration and a tool scope only for that tool's native, non-shared configuration.
- When `.commitlintrc.json` changes, update the mirrored lists in `.codex/settings.toml` and the VS Code commit prompt in `.vscode/settings.json`.

## Scoped rules

- Agent sources, loader routes, skills, hooks, and private configuration: `agent-config.md`.
- Shell startup, Git internals, package ownership, VS Code extensions, and machine reconciliation: `shell-dotfiles.md`.
- Tracked launch agents and their loading: `launchd.md`.
