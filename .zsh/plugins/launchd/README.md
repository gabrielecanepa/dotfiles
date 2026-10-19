# launchd plugin

Manages user-defined launch agents in a configurable folder and repairs their installation on shell startup.

To use it, add `launchd` to the plugins array in your zshrc file:

```zsh
plugins=(... launchd)
```

## Usage

The plugin defines no commands. On macOS, it runs a detached background worker when loaded. On other operating systems, it does nothing.

Store agents in `${XDG_CONFIG_HOME:-$HOME/.config}/launchd/<label>.plist`. Each plist must be valid, and its filename stem must equal its `Label`. Labels must start with a letter or digit and contain only letters, digits, periods, underscores, or hyphens.

For each agent, the worker creates a symlink in `$HOME/Library/LaunchAgents`. launchd discovers these links at GUI login. The worker also bootstraps enabled agents into the current GUI session, reloads changed definitions, and repairs missing or redirected plugin-owned symlinks. An unloaded enabled agent is bootstrapped again on the next shell startup.

Set `<key>Disabled</key><true/>` to unload an agent on the next reconciliation. Its symlink remains installed, with the disabled definition. Remove the source plist to unload the job and remove its plugin-owned link and state. A missing source directory is a no-op, not a request to retire every agent.

The worker never replaces unrelated files or symlinks or adopts an already-loaded label without ownership state. If a managed link is replaced by a regular file, it reports the conflict without changing the file or job. Reconciliation is serialized by a process-held lock, so simultaneous shell startups cannot compete.

Success is silent. Validation, ownership, and launchctl failures go to stderr and are retried on the next shell startup. Scheduled and on-demand jobs may be loaded without a running process; execution and supervision remain launchd's responsibility. This plugin does not provide continuous health monitoring or change launchctl's enable/disable overrides.

## Settings

Set these variables before loading the plugin:

```zsh
LAUNCHD_DIR="$HOME/path/to/agents"
```

`LAUNCHD_DIR` overrides the source directory. It defaults to `${XDG_CONFIG_HOME:-$HOME/.config}/launchd`. It must differ from `$HOME/Library/LaunchAgents`.

`XDG_STATE_HOME` controls ownership and loaded-definition storage. State lives in `${XDG_STATE_HOME:-$HOME/.local/state}/launchd`, separate from the source plists. Preserve this state so the plugin can distinguish its own jobs and links from unrelated ones.

Changing `LAUNCHD_DIR` reconciles the new folder against the existing ownership state. Changing `XDG_STATE_HOME` does not migrate that state or adopt previously loaded jobs.
