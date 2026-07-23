---
description: 'Use when writing or editing shell scripts (.sh/.bash/.zsh). Machine-wide script conventions: shebang choice, file header comment format, and fail-fast vs degrade-gracefully error handling. Dotfiles-repo shell internals live in dotfiles.instructions.md.'
applyTo: '**/*.sh, **/*.bash, **/*.zsh'
paths:
  - '**/*.sh'
  - '**/*.bash'
  - '**/*.zsh'
---

# Shell scripts

- Shebang: `#!/usr/bin/env bash` (or `zsh`): env resolves the interpreter from PATH, so scripts get the Homebrew bash instead of the frozen macOS `/bin/bash` 3.2. POSIX sh scripts use `#!/bin/sh`: the path is guaranteed and `env` adds nothing. Sourced-only files carry a shebang only when editors and linters need it for language detection.
- Headers are optional; trivial or self-describing files (rc files, alias lists, small hooks) stay bare. When a script earns one, executables use the Google block: shebang, bare `#` spacer, description (plus usage or arguments when needed), blank line, code. Sourced files use a description-only comment block from line 1. Never close a header with a trailing `#`.
- Error mode follows the consumer. Standalone task scripts and gatekeeper hooks (git hooks) fail fast: `set -euo pipefail` in bash, `set -eu` in POSIX sh, where pipefail is not portable. Scripts whose output another program renders or that must fail open (statuslines, agent hooks, prompt segments) never use `set -e`: `set -uo pipefail` in bash, `set -u` in sh, plus explicit fallbacks, so a failing probe (`git` in a non-repo dir) falls back instead of aborting and blanking the output. Sourced shell config sets no flags.
