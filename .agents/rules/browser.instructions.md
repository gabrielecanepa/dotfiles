---
description: 'Use whenever a task drives or verifies a real web UI. Reuse the running app, use agent-browser, preserve authenticated state, and clean up sessions.'
applyTo: '**/*.astro, **/*.css, **/*.html, **/*.jsx, **/*.svelte, **/*.tsx, **/*.vue'
paths:
  - '**/*.astro'
  - '**/*.css'
  - '**/*.html'
  - '**/*.jsx'
  - '**/*.svelte'
  - '**/*.tsx'
  - '**/*.vue'
---

# Real-browser work

Use the `agent-browser` skill for browser driving, QA, screenshots, scraping, and authenticated flows. Test the running application with its real data. Never create a throwaway page, mock route, auth bypass, or ad-hoc preview server.

## Flow

- Reuse the dev server and port already running. Read the terminal, open tabs, or project config. If none exists, start the project's own dev command with its lockfile-selected package manager and configured port.
- Load the workflow with `agent-browser skills get core`. Use a session named for the worktree or task, act on snapshot refs, wait for real URL, text, or network signals, and capture evidence for the changed behavior.
- If the CLI is missing or broken, repair it yourself and rerun: `npm i -g agent-browser && agent-browser install`, then `nodenv rehash` if the command is still missing. A binary that fails `--version`, such as a version link dangling into a removed worktree, counts as broken. Do not hand the reinstall to the user unless blocked.

```sh
agent-browser --session <task> open http://localhost:<port>/<route>
agent-browser --session <task> snapshot -i
agent-browser --session <task> close
```

## Session cleanup

Every launched session must be closed, including on failure. A session whose owning process exits without closing leaves an orphaned daemon holding roughly 900 MB across a dozen Chrome processes, and a few of those add up to gigabytes of swap.

- Close the session in the same turn that finishes with it. Never hold one open across a handoff, a blocked task, an error path, or for a later turn to reuse; relaunching is cheap.
- Pair every launch with its close so an early return cannot skip cleanup. Close in a trap or equivalent when a script drives the CLI.
- After a failed, timed-out, or uncertain run, close only that named session. Run `agent-browser close --all` only when no other browser work is active.
- Reap survivors when a session already died: kill `agent-browser` processes whose parent is `1`, then remove session and config state older than three days.

```sh
agent-browser close --all
pgrep -f 'node_modules/agent-browser|\.agent-browser/browsers'
```

Do not register `cleanup-agent-browser.sh` as a generic session-end hook. It closes every local browser session, and the daemon it reaps runs with parent `1` even while healthy, so both halves can interrupt another agent's active work. Run it manually only after a failed or abandoned run, and only when no other browser work is active.

## Authentication

The vault may fill credentials because the model never sees the secret. Use this order before reporting a block:

1. Launch with the project's persistent `--session-name <profile>` so cookies and storage restore across runs.
2. If the login page appears, run `agent-browser auth login <profile>`. The project instructions must name the profile and login URL.
3. If `agent-browser auth list` lacks the profile, print the following command with project values filled in and stop for the user to enter the password:

   ```sh
   read -rs PW && printf '%s' "$PW" | agent-browser auth save <profile> --url <login-url> --username <test-user> --password-stdin && unset PW
   ```

For SSO or magic links that the vault cannot script, have the user log in once, save state to a gitignored file, set `AGENT_BROWSER_ENCRYPTION_KEY`, and relaunch with `--state`. A read-only Chrome profile snapshot is the last fallback and goes stale with Chrome's session. Never put a password on the command line.

Use the active agent's visible-browser integration only when the user explicitly requests their browser. List connected browsers first, select an unambiguous named window, reuse its existing app tab, and clean up any group you create.
