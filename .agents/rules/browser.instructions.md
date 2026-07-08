---
description: 'Use whenever a task drives a real browser: verifying a change in the running app, QA, dogfooding, form/flow automation, scraping, screenshots. Reuse the running dev server, drive it through agent-browser, and clean up on completion. Always-on: browser work is an action, not a file edit, so nothing path-scoped would trigger it.'
---

# Real-browser work

Route all real-browser work through the **`agent-browser`** skill (the CLI). Reach for `claude-in-chrome` (or `Control_Chrome`) only in the fallback case below. Never build a throwaway HTML file and serve it on an ad-hoc port to preview a feature: that bypasses the running app, its auth, and its real data. Drive the actual app.

## 1. One dev server, reuse its port

- The user runs the dev server (`next dev`, `vite`, etc.). **Reuse the port it already serves on** (Next defaults to `3000`, but read the actual port: the terminal banner, `list_tabs`, or the project's dev script/config). That port holds the authenticated session and real state a fresh server lacks.
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

## 3. Fallback: the user's logged-in profile

Use **`claude-in-chrome`** instead of `agent-browser` only when the task needs the user's real Chrome profile/session (a login `agent-browser`'s vault can't reproduce) or the user wants to watch it happen live in their own window. Then:

- `list_connected_browsers` first. The user names their windows (e.g. **Work**, **Omney**); pick the one that matches the task. If it's ambiguous, none is open, or the windows are unnamed, **ask** rather than guessing.
- Reuse the tab already on the running app; don't open a new window. Same cleanup rule: delete any tab group you created and marked completed.
