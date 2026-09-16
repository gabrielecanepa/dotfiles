# Browser procedures

The procedures and rationale behind `browser.md`. Read the section the current task needs.

## Why Homebrew only

- `agent-browser` is a machine-level CLI, like Chrome itself, never a dependency of a repository.
- Its profiles, downloaded Chrome, sessions, and encryption key live in `~/.agent-browser`, shared by every repository and worktree.
- A per-repository pin in `package.json` fragments the binary driving one shared store and costs about 87 MB per checkout.
- nodenv scopes `npm i -g` to one Node version, so a Node bump or global prune silently swaps or removes the binary and strands the old copy.
- The Homebrew keg is one machine-wide 10 MB copy on the non-interactive PATH; `agent-browser upgrade` detects the install method.
- `npx agent-browser` with no local copy downloads whatever the registry tags `latest`, a version nobody chose.
- Upstream skills such as `next-dev-loop` call the bare command, so the bare form is the only one that stays consistent.

## Repair

- A binary that fails `agent-browser --version`, such as a version link dangling into a removed worktree, counts as broken.
- Reinstall with `brew reinstall agent-browser && agent-browser install`.
- When an npm global is present, run `NODENV_VERSION=<version> npm uninstall -g agent-browser` for every Node version that has one.
- Then run `nodenv rehash`; a dead shim keeps shadowing the Homebrew binary.

## Why headless

- `--headed` activates Chrome for Testing on every launch and takes focus and the frontmost window.
- No launch flag, bundle plist key, or minimized window state prevents that.
- Screenshots, snapshots, clicks, React introspection, and vitals all work headless.

## Orphaned sessions

- A session whose owning process exits without closing leaves an orphaned daemon holding roughly 900 MB across a dozen Chrome processes.
- A few orphans add up to gigabytes of swap.
- Reap survivors: kill `agent-browser` processes whose parent is `1`, then remove session and config state older than three days.
- `cleanup-agent-browser.sh` closes every local browser session and reaps the daemon, which runs with parent `1` even while healthy.
- Both halves can interrupt another agent's active work, which is why it never runs as a hook.

```sh
agent-browser close --all
pgrep -f 'node_modules/agent-browser|\.agent-browser/browsers'
```

## Authentication ladder

The vault may fill credentials because the model never sees the secret. Use this order before reporting a block:

1. Launch headless with `--session-name <profile>`.
2. Under `--json`, `data.lifecycle.restoreStatus` reports `loaded` when the saved session is live, and `missing` or `loaded_but_invalid` when a login is due.
3. When the login page appears, run `agent-browser auth login <profile>`.
4. When `agent-browser auth list` lacks the profile, print the command below with project values filled in and stop for the user to enter the password.
5. For SSO or magic links the vault cannot script, have the user log in once, save state to a gitignored file, and relaunch with `--state`.
6. A read-only Chrome profile snapshot is the last fallback and goes stale with Chrome's session.
7. Headed covers the user action only: relaunch the same session with `--headed`, pause until the user confirms, then reissue the command without it.
8. `--restore` saves and reloads cookies and localStorage across both relaunches, so the window appears once.

```sh
read -rs PW && printf '%s' "$PW" | agent-browser auth save <profile> --url <login-url> --username <test-user> --password-stdin && unset PW
```

Set `AGENT_BROWSER_ENCRYPTION_KEY` before saving or loading `--state` files.

## Visible-browser integration

- `claude-in-chrome` (`mcp__claude-in-chrome__*`) drives the user's own browser, so live sessions can be evicted.
- It cannot restore state the way `--restore` does.
- List connected browsers first, select an unambiguous named window, reuse its existing app tab, and clean up any tab group you create.
