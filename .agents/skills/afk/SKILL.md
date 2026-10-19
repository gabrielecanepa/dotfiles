---
name: afk
description: >-
  Mobile remote mode: results arrive in chat as a live preview URL, desktop screenshots, and summaries, and "ship" publishes.
  Use for /afk, /afk off, or when the user is on a phone or away from a desk.
---

# Using Away From Keyboard (AFK) Mode

The user is working from a phone and cannot open files, a terminal, an IDE, or a desktop browser, so everything needed to judge the work arrives in chat.

The contract is harness and stack agnostic: Claude Code and Codex get named tools, every step has a fallback, and the stack and git host are detected.

## Activation

- On bare `/afk`, turn the mode on, run the preview bootstrap now, then reply with the live URL and a one-line ready message.
- On `/afk <task>`, run the same bootstrap, then start the task immediately under this contract.
- On `/afk off`, do not reload the contract; follow "Leaving the mode" below.
- Keep the mode for the whole session, including after a context compaction or a long gap, unless the user turned it off.
- When the work moves to a different project or worktree, rerun the bootstrap.

## Output shape

- Lead with the outcome in one or two sentences, then only the detail needed to decide the next step.
- Keep messages scannable on a phone: no table wider than three columns, no code block longer than about ten lines unless the user asks for code.
- Never point to a file path or command output as the answer; state the relevant content directly in the message.

## Dictated input

- Expect transcription artifacts: homophones ("get" for "git", "cash" for "cache"), mangled identifiers and package names, missing punctuation, run-on phrasing.
- Map a garbled term to the nearest real file, branch, command, or dependency in this project.
- Note the interpretation in passing ("reading that as `pnpm lint`") so a wrong guess is caught at a glance.
- Ask only when plausible readings lead to materially different work.
- Before a destructive action, always confirm the interpretation first.

## Live preview server

Every update carries a URL where the current state of the app runs, reachable from the phone over Tailscale, pointing at the code this session edits.

- Follow [references/live-preview.md](references/live-preview.md) for preconditions, hostname resolution, dev server detection, and port exposure.
- Treat the tailnet URL as the place to interact with the live app; it renders with the phone's viewport, so desktop layout is judged from screenshots.

## Close every update

End each unit of work with this sequence, skipping only lines that do not apply:

1. Verification: run the project's checks (types, lint, tests) and report pass or fail with the command used.
2. Diff summary: one line per changed file as `path:line, resulting behavior`; describe behavior, not mechanics.
3. Links: one compact block with the live preview URL, the PR or MR, the deploy preview (Vercel, Cloudflare, Netlify, or other), and CI status, when they exist.
4. Desktop screenshots: when the change can affect rendered UI, send them here as the closing attachment of the update.
5. Next step: a closed question offering the likely next actions (continue, adjust, ship, stop).

- Deliver the closed question through the harness's prompt (AskUserQuestion in Claude Code); otherwise end with a short numbered list answerable with one word.

## Desktop screenshots

- Capture at viewport 1440x900, full page, one image per affected route or state.
- Never use a mobile viewport or let the page adapt to a small width; exact desktop rendering is the point.
- Capture against this session's dev server, the one behind the live preview URL.
- Drive it with the browser automation the environment offers: the agent-browser skill, Playwright, or another headless browser.
- Save images to the session scratch or temp directory, never the repository.
- Send them with the harness's attachment tool (SendUserFile in Claude Code); without one, use the hosting fallback in the reference.

## Ship trigger

"ship", alone or with extra notes, is the explicit ask the standing commit boundary requires. It authorizes exactly three steps:

1. Commit the session's changes following the repository's commit convention.
2. Push and open the request with the host's CLI: `git push -u origin HEAD && gh pr create --fill` on GitHub, `glab mr create --fill --yes` on GitLab.
3. Reply with the link and a one-line summary.

### Ship boundaries

- Ship covers only this session's work in the checkout the current turn acts in; name that checkout when more than one is live.
- Never merge and never force-push; anything beyond commit, push, and open request needs its own ask.
- Skip confirmation on a clean "ship"; confirming would cost the round trip the word exists to save.
- When "ship" arrives inside garbled or fragmentary dictation, echo the scope back and wait, because "don't ship yet" can lose its first two words.

### Without a CLI

- With neither `gh` nor `glab` installed, push and reply with the host's compare URL so one tap opens the form.
- GitHub: `<repo>/compare/<base>...<head>?expand=1`.
- GitLab: `<repo>/-/merge_requests/new?merge_request%5Bsource_branch%5D=<branch>`.

## Leaving the mode

- On `/afk off`, or when the user says they are back at a desktop ("back at my desk", "back on the Mac"), drop this contract and return to normal output.
- Turn off only the tailscale serve listeners this session added.
- Leave dev servers running; they cost nothing locally and the user may return.
