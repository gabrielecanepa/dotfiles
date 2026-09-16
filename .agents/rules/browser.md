---
description: 'Use whenever a task drives or verifies a real web UI. Reuse the running app, drive it with agent-browser headless, keep authenticated state, close every session.'
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

Procedures, rationale, and recovery steps: `~/.agents/references/browser-procedures.md`.

## Tool

- Use the `agent-browser` skill for browser driving, QA, screenshots, scraping, and authenticated flows.
- Keep `agent-browser` as the default when a browser MCP such as `claude-in-chrome` is loaded; an available tool is not an instruction to use it.
- Test the running application with its real data; never create a throwaway page, mock route, auth bypass, or ad-hoc preview server.
- Call it as `agent-browser`, never `npx agent-browser`.
- When a skill states a minimum version, check `agent-browser --version` and run `agent-browser upgrade` first.
- Install and update it only through Homebrew (`brew install agent-browser && agent-browser install`, then `agent-browser upgrade`); never `npm i -g`.
- When the CLI is missing or fails `--version`, repair it yourself per the reference and rerun; hand the reinstall to the user only when blocked.

## Flow

- Reuse the dev server and port already running; find it in the terminal, open tabs, or project config.
- When no server runs, start the project's own dev command with its lockfile-selected package manager and configured port.
- Load the workflow with `agent-browser skills get core`; name the session after the worktree or task.
- Act on snapshot refs, wait for real URL, text, or network signals, and capture evidence for the changed behavior.
- Run headless; drop `--headed` even when a skill's own example passes it, `next-dev-loop` included.

```sh
agent-browser --session <task> open http://localhost:<port>/<route>
agent-browser --session <task> snapshot -i
agent-browser --session <task> close
```

## Session cleanup

- Close every launched session in the same turn that finishes with it, including on failure.
- Never hold a session open across a handoff, a blocked task, or a later turn; relaunching is cheap.
- Pair every launch with its close; when a script drives the CLI, close in a trap.
- After a failed, timed-out, or uncertain run, close only that named session.
- Run `agent-browser close --all` only when no other browser work is active.
- When a session already died, reap survivors per the reference.
- Never register `cleanup-agent-browser.sh` as a session-end hook; run it manually after a failed run, only when no other browser work is active.

## Authentication

- Launch headless with the project's persistent `--session-name <profile>` so cookies and storage restore across runs.
- When the login page appears, run `agent-browser auth login <profile>`; the project instructions must name the profile and login URL.
- When `agent-browser auth list` lacks the profile, print the save command from the reference with project values and stop for the user.
- Never put a password on the command line.
- For SSO or magic links, have the user log in once, save state to a gitignored file, set `AGENT_BROWSER_ENCRYPTION_KEY`, and relaunch with `--state`.
- Use `--headed` only as the last rung, for the user's action alone; relaunch with `--restore`, wait for the user, then reissue the command headless.
- Use `claude-in-chrome` only when the user asks or the task needs state in the user's own browser profile; follow the reference for tab hygiene.
