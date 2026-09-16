---
description: 'Use when writing or editing shell scripts (.sh, .bash, .zsh): shebangs, headers, and fail-fast versus fail-open behavior. Dotfiles startup and package internals live in shell-dotfiles.md.'
applyTo: '**/*.sh, **/*.bash, **/*.zsh'
paths:
  - '**/*.sh'
  - '**/*.bash'
  - '**/*.zsh'
---

# Shell scripts

## Shebang

- Bash and zsh scripts start with `#!/usr/bin/env bash` or `#!/usr/bin/env zsh`, so PATH resolves the Homebrew interpreter, not the frozen `/bin/bash` 3.2.
- POSIX sh scripts start with `#!/bin/sh`; the path is guaranteed and `env` adds nothing.
- Sourced-only files carry a shebang only when editors and linters need it for language detection.

## Header

- Trivial or self-describing files (rc files, alias lists, small hooks) stay bare.
- When an executable earns a header, use the Google block: shebang, bare `#` spacer, description with usage or arguments when needed, blank line, code.
- A sourced file uses a description-only comment block from line 1.
- Never close a header with a trailing `#`.

## Error mode

- Standalone task scripts and gatekeeper hooks (git hooks) fail fast: `set -euo pipefail` in bash, `set -eu` in POSIX sh, where pipefail is not portable.
- Scripts whose output another program renders, or that must fail open (statuslines, agent hooks, prompt segments), never use `set -e`.
- Fail-open scripts use `set -uo pipefail` in bash or `set -u` in sh plus explicit fallbacks, so a failing probe falls back instead of blanking the output.
- Sourced shell config sets no flags.
