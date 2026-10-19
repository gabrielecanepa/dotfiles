---
description: "Use when writing or editing shell scripts and startup files (.sh, .bash, .zsh, .zsh-theme, .zshrc, .bashrc, .profile): shebangs, headers, quoting, paths, sourcing, and fail-fast versus fail-open behavior."
applyTo: "**/.bash_profile,**/.bashrc,**/.profile,**/.zprofile,**/.zshenv,**/.zshrc,**/*.bash,**/*.sh,**/*.zsh-theme,**/*.zsh"
paths:
  - "**/.bash_profile"
  - "**/.bashrc"
  - "**/.profile"
  - "**/.zprofile"
  - "**/.zshenv"
  - "**/.zshrc"
  - "**/*.bash"
  - "**/*.sh"
  - "**/*.zsh-theme"
  - "**/*.zsh"
---

# Shell

## Shebang

- Bash and zsh scripts start with `#!/usr/bin/env bash` or `#!/usr/bin/env zsh`, so PATH resolves the Homebrew interpreter and not the frozen `/bin/bash`.
- POSIX sh scripts start with `#!/bin/sh`: the path is guaranteed and `env` adds nothing.
- Sourced-only files have a shebang only when editors and linters need it for language detection.

## Header

- Trivial or self-describing files (rc files, alias lists, small hooks) stay bare.
- When an executable needs a header, use: shebang, bare `#` spacer, description and any required usage, blank line, code.
- Never close a header with a trailing `#`.
- A sourced file can use a description-only comment block from line 1.

## Quoting

- Write a single word without quotes: `ZSH_THEME=squanchy`, `HIST_STAMPS=yyyy-mm-dd`, `alias pn=pnpm`.
- Use single quotes for literals with whitespace or special characters: `EDITOR='code --wait'`.
- Put `zstyle` contexts in single quotes: `zstyle ':omz:update' frequency 7`.

## Expansions

- In native zsh with `SH_WORD_SPLIT` and `GLOB_SUBST` unset, omit expansion quotes unless one of these cases applies:
  - The word mixes an expansion with whitespace or special characters: `"%{$fg[green]%}"`.
  - An empty value must stay an argument: `cd "$dir"`.
  - A command substitution is an argument or an array element, because zsh splits it: `print -r -- "$(date)"`.
  - All arguments or all array elements: `"$@"`, `"${array[@]}"`.
- In Bash and POSIX sh, place every expansion in double quotes, also in assignments: `PATH="$HOME/bin:$PATH"`.

## Zsh path arrays and prompts

- In zsh path arrays, omit quotes around `${var:+$var/bin}` so an unset optional path does not add an empty entry.
- Preserve prompt quoting; deferred parameter expansion depends on the shell's prompt-substitution settings.

## Paths and sourcing

- Use `~/...` where tilde expansion applies: unquoted word start, assignment start or after `:`, or a `${var:-~/...}` default in zsh.
- Write `$HOME` where `~` does not expand: inside double quotes, after `=` in an option, in a pattern, and in a string that another program reads.
- Use `source` in zsh and Bash; use `.` in POSIX sh, where `source` is not defined.

## Error mode

- Standalone task scripts and Git gate hooks fail fast: use `set -euo pipefail` in Bash or `set -eu` for older POSIX sh targets.
- Scripts that must fail open, such as statuslines and agent hooks, never use `set -e`; handle probe failures explicitly.
- Fail-open scripts use `set -uo pipefail` in Bash or `set -u` in sh, with safe fallbacks for unset values and failed commands.
- Sourced shell configuration sets no flags; preserve the caller's options.
