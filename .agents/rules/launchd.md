---
description: "Use for user LaunchAgents in .config/launchd and their plugin: portable sh wrappers, ownership, enabled state, safe retirement, and performance."
applyTo: ".config/launchd/**,.zsh/plugins/launchd/**"
paths:
  - ".config/launchd/**"
  - ".zsh/plugins/launchd/**"
---

# Launch agents

## Tracking and loading

- Track each agent as `.config/launchd/<label>.plist`; the filename stem must equal `Label`.
- The `launchd` plugin reconciles plists asynchronously at shell startup with a process-held lock.
- Source plists get plugin-owned symlinks in `$HOME/Library/LaunchAgents`, so launchd discovers them at GUI login.
- The worker bootstraps enabled jobs and reloads changed definitions in the current GUI session.
- Ownership links and loaded snapshots live under `${XDG_STATE_HOME:-$HOME/.local/state}/launchd`; preserve them.
- Set `LAUNCHD_DIR` to override `${XDG_CONFIG_HOME:-$HOME/.config}/launchd`; keep it separate from the installation directory.
- Never replace unrelated installation entries or adopt a loaded label without ownership state.
- Reconciliation checks loaded definitions, not continuous application health or whether every job has a running process.

## Plist contents

- For these agents, set `ProgramArguments` to `/bin/sh -c` with a short script; launchd does not perform shell expansion.
- The script exports `PATH` and `LANG`, runs `cd "$HOME"`, and ends with `exec <command> >/dev/null 2>>"$HOME/Library/Logs/<label>.log"`.
- Set the wrapper's `PATH` explicitly with `/opt/homebrew/bin:/usr/local/bin`; never rely on `$HOMEBREW_PREFIX` in launchd.
- Never write `~`, a `/Users` path, or a bare binary outside the wrapper.
- Omit `ProcessType` by default; choose `Background` only for work that can accept lower scheduling and I/O priority.

## Enabling and retiring

- `Disabled` is the declarative switch: `<false/>` for an active agent, `<true/>` to make the next shell unload the job.
- To retire an agent, delete its source plist; the next shell unloads the plugin-owned job and removes its link and state.
- When the source directory is missing, reconciliation does nothing; never treat that as removal of every agent.
- Never use `launchctl enable` or `disable`; their external state overrides the plist.
