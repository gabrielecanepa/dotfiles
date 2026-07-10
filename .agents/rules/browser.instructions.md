---
description: 'Use whenever a task drives a real browser: verifying a change in the running app, QA, dogfooding, form/flow automation, scraping, screenshots. Reuse the running dev server, drive it through agent-browser, and clean up on completion. Always-on: browser work is an action, not a file edit, so nothing path-scoped would trigger it.'
---

# Real-browser work

Route all real-browser work through the **`agent-browser`** skill (the CLI), authenticated pages included (section 3). Reach for `claude-in-chrome` (or `Control_Chrome`) ONLY if explicitly requested by the user (section 4). NEVER build a throwaway HTML file and serve it on an ad-hoc port to preview a feature: that bypasses the running app, its auth, and its real data. Drive the actual app.

## 1. One dev server, reuse its port

- The user runs the dev server (`next dev`, `vite`, etc.). **Reuse the port it already serves on** (read the actual port: the terminal banner, `list_tabs`, or the project's dev script/config). That port holds the authenticated session and real state.
- **Never spawn a per-launch server** (a random port like `8899`, a `.claude/launch.json` entry, `python -m http.server`) to preview or verify a feature. If no dev server is running, start the project's own (`pnpm dev` / the lockfile's package manager) on its configured port, or ask which port to use; do not invent one.
- Detect the package manager from the lockfile (`pnpm-lock.yaml` → pnpm, `package-lock.json` → npm, `bun.lockb` → bun); never assume.

## 2. The verify loop

Canonical loop, scoped to an isolated session so parallel work never collides (name it after the worktree/branch):

```bash
agent-browser --session <worktree> open http://localhost:<port>/<route>
agent-browser --session <worktree> snapshot -i      # act on @eN refs
# ...drive the real flow: click, fill, wait, screenshot...
agent-browser --session <worktree> close            # on completion, always
```

- Load the full workflow first: `agent-browser skills get core`. Wait on real signals (`wait --url`, `wait --text`, `wait --load networkidle`), not bare `wait 2000`.
- **Close the session when the task is done** (`close`, or `close --all` for every session). Leaving a live session or dead tab behind is the failure to avoid. If you opened a tab group, delete it on completion; a completed group (green-check icon) must not be left in the window.

## 3. Authenticated pages

When the route needs a logged-in session, seed it from the user's real Chrome profile instead of scripting a login. `--profile <name>` copies that profile to a read-only snapshot, so the agent inherits the live cookies without touching the real profile:

```bash
agent-browser profiles                                          # list profiles by name
agent-browser --profile "<Name>" --session <worktree> open http://localhost:<port>/<route>
```

- The snapshot is taken at launch: if the session cookie expired in Chrome, the copy is stale, so re-run after logging in fresh.
- To keep the login warm across runs, add `--session-name <key>` (auto-saves cookies/storage to `~/.agent-browser/sessions/` on close, restores next launch). Note the two look-alike flags: `--session` is an isolated browser instance (the verify-loop scope above), `--session-name` is the auth-persistence key.
- Other paths, weaker: a scriptable username/password form → the credential vault (`auth save <name> --password-stdin` once, then `auth login <name>`; the LLM never sees the password). A login the vault can't script (SSO, magic link) → `state save ./auth.json` once, then `--state ./auth.json`. State files are plaintext tokens: gitignore them and set `AGENT_BROWSER_ENCRYPTION_KEY`. Never put a real password on the command line (shell-history leak).

## 4. Fallback: watch it live in the user's window

Use **`claude-in-chrome`** (or `Control_Chrome`) instead of `agent-browser` ONLY when if user explicitly requests it. Then:

- `list_connected_browsers` first. The user names their windows (e.g. **Work**, **<Company>x**); pick the one that matches the task. If it's ambiguous, none is open, or the windows are unnamed, **ask** rather than guessing.
- Reuse the tab already on the running app; don't open a new window. Same cleanup rule: delete any tab group you created and marked completed.
