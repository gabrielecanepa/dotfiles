---
description: 'Use only in the $HOME dotfiles repository. Owns portability, allowlist tracking, and the repository commit convention; routes agent configuration, shell internals, and launchd to scoped companion rules.'
applyTo: '.agents/**,.claude/**,.codex/**,.config/**,.copilot/**,.github/**,.homebrew/**,.local/**,.npm/**,.vscode/**,.zed/**,.zsh/**,.aliases,.bash_profile,.bashrc,.commitlintrc,.editorconfig,.gemrc,.gitconfig,.gitignore,.install.sh,.irbrc,.macos,.node-version,.npmrc,.oxfmtrc.json,.profile,.python-version,.rubocop.yml,.ruby-version,.shellcheckrc,.vault,.vimrc,.zprofile,.zshenv,.zshrc'
paths:
  - '.agents/**'
  - '.claude/**'
  - '.codex/**'
  - '.config/**'
  - '.copilot/**'
  - '.github/**'
  - '.homebrew/**'
  - '.local/**'
  - '.npm/**'
  - '.vscode/**'
  - '.zed/**'
  - '.zsh/**'
  - '.aliases'
  - '.bash_profile'
  - '.bashrc'
  - '.commitlintrc'
  - '.editorconfig'
  - '.gemrc'
  - '.gitconfig'
  - '.gitignore'
  - '.install.sh'
  - '.irbrc'
  - '.macos'
  - '.node-version'
  - '.npmrc'
  - '.oxfmtrc.json'
  - '.profile'
  - '.python-version'
  - '.rubocop.yml'
  - '.ruby-version'
  - '.shellcheckrc'
  - '.vault'
  - '.vimrc'
  - '.zprofile'
  - '.zshenv'
  - '.zshrc'
---

# Dotfiles repository

These rules apply only when `$HOME` is the active repository. Treat every file under `~` as potentially tracked and preserve unrelated work.

## Portability and tracking

- Every tracked file must work on a fresh machine. Use `$HOME`, `~`, `$HOMEBREW_PREFIX`, `$XDG_*`, or repository-relative paths instead of a user path, hostname, serial, personal email, or other machine identity. Keep identity and private state in their existing ignored owners.
- The `/opt/homebrew` and `/usr/local` PATH pair is the only approved machine-location exception because bootstrap code runs before `$HOMEBREW_PREFIX` exists. Other exceptions require explicit approval. Standard system paths such as `/bin/sh`, `/etc`, `/Users/Shared`, and `/usr/bin/env` are portable.
- `.gitignore` is an allowlist that starts with `/*`. Add a matching `!` rule with every new tracked path. The managed-file hook blocks edits through linked or generated routes, and the writing hook plus `pre-push` reject committed user paths.

## Commit convention

- `.commitlintrc` and `.config/git/hooks/commit-msg` enforce an allowlisted lower-case type, an optional allowlisted lower-case scope, and a non-empty subject. Do not use `feat`, `fix`, or `refactor`.
- Allowed types: `agents`, `brew`, `chore`, `docs`, `git`, `gui`, `node`, `python`, `ruby`, `shell`.
- Repository convention keeps the subject lower-case with no trailing period. Scope parents are also conventional: `agents` uses `claude`, `codex`, or `copilot`; `brew` uses `cask`, `formula`, or `mas`; `gui` uses `ghostty`, `vscode`, or `zed`; `node` uses `npm`; `shell` uses `bash`, `sh`, or `zsh`.
- Use `agents` for shared agent configuration. Use a tool scope only for its native, non-shared configuration.

## Scoped rules

- Agent sources, loader routes, skills, hooks, and private configuration: `agent-config.instructions.md`.
- Shell startup, Git internals, package ownership, VS Code extensions, and ongoing machine reconciliation: `shell-dotfiles.instructions.md`.
- LaunchAgent templates and rendering: `launchd.instructions.md`.
