---
description: 'Use when writing or editing shell scripts (.sh/.bash/.zsh). Machine-wide script conventions: shebang choice, file header comment format, and fail-fast vs degrade-gracefully error handling. Dotfiles-repo shell internals live in dotfiles.instructions.md.'
applyTo: '**/*.sh, **/*.bash, **/*.zsh'
paths:
  - '**/*.sh'
  - '**/*.bash'
  - '**/*.zsh'
---

# Shell scripts

- Shebang: `#!/usr/bin/env bash` unless the consumer requires another interpreter.
- Headers: shebang, one `# description` line, blank line, code. Only when the header needs several lines (usage, arguments) use the Google style block: shebang, bare `#` spacer, comment lines, blank line.
- Error mode follows the consumer. Standalone task scripts fail fast with `set -euo pipefail`. Scripts whose output another program renders (statuslines, hooks, prompt segments) must degrade gracefully: `set -uo pipefail` plus explicit fallbacks, never `set -e`, so a failing probe (`git` in a non-repo dir) falls back instead of aborting and blanking the output.
