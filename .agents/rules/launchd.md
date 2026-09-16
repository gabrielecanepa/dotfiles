---
description: 'Use for the tracked LaunchAgents under ~/Library/LaunchAgents and their dotfiles loader: portable sh wrappers, labels, enabled state, safe retirement, and performance.'
applyTo: 'Library/LaunchAgents/**,.install.sh,.zsh/plugins/dotfiles/**'
paths:
  - 'Library/LaunchAgents/**'
  - '.install.sh'
  - '.zsh/plugins/dotfiles/**'
---

# Launch agents

## Tracking and loading

- Track a custom agent in place as `Library/LaunchAgents/<label>.plist`, allowlisted one by one in `.gitignore`.
- The filename stem must equal `Label`.
- `dotfiles init` loads every allowlisted agent not loaded or changed since its last load and unloads disabled ones; `dotfiles doctor` reports drift.
- The `launchd` reconciler at `.zsh/plugins/dotfiles/reconcilers/launchd.zsh` owns that logic and exposes `_launchd_drift` and `_launchd_reconcile`.
- Load state is a marker file under `${XDG_STATE_HOME:-~/.local/state}/dotfiles/launchd/<label>`, so editing a plist reloads it on the next init.
- Leave third-party plists in the same directory ignored and untouched.

## Plist contents

- launchd expands nothing at runtime, so `ProgramArguments` is `/bin/sh -c` with a short script.
- The script exports `PATH` and `LANG`, runs `cd "$HOME"`, and ends with `exec <command> >/dev/null 2>>"$HOME/Library/Logs/<label>.log"`.
- launchd sets only `HOME`, `USER`, `SHELL`, and `TMPDIR`, so `PATH` uses the approved `/opt/homebrew/bin:/usr/local/bin` pair, never `$HOMEBREW_PREFIX`.
- Never write `~`, a `/Users` path, or a bare binary outside the wrapper.
- Omit `ProcessType`; the `Background` value pins the job and its children to efficiency cores, roughly 3.5x slower.

## Enabling and retiring

- `Disabled` is the declarative switch: `<false/>` for an active agent, `<true/>` to make the next init unload the job.
- To retire an agent, set `<true/>`, run `dotfiles init`, then delete the file and its `.gitignore` line.
- Never use `launchctl enable` or `disable`; their external state overrides the plist.
