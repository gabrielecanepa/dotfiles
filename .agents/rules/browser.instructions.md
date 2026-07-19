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
- Close the session when finished. Remove any tab group created for the task.

```sh
agent-browser --session <task> open http://localhost:<port>/<route>
agent-browser --session <task> snapshot -i
agent-browser --session <task> close
```

## Authentication

The vault may fill credentials because the model never sees the secret. Use this order before reporting a block:

1. Launch with the project's persistent `--session-name <profile>` so cookies and storage restore across runs.
2. If the login page appears, run `agent-browser auth login <profile>`. The project instructions must name the profile and login URL.
3. If `agent-browser auth list` lacks the profile, print the following command with project values filled in and stop for the user to enter the password:

   ```sh
   read -rs PW && printf '%s' "$PW" | agent-browser auth save <profile> --url <login-url> --username <test-user> --password-stdin && unset PW
   ```

For SSO or magic links that the vault cannot script, have the user log in once, save state to a gitignored file, set `AGENT_BROWSER_ENCRYPTION_KEY`, and relaunch with `--state`. A read-only Chrome profile snapshot is the last fallback and goes stale with Chrome's session. Never put a password on the command line.

Use `claude-in-chrome` or `Control_Chrome` only when the user explicitly requests their visible browser. List connected browsers first, select an unambiguous named window, reuse its existing app tab, and clean up any group you create.
