---
name: afk
description: >-
  Mobile remote mode: results arrive in chat as a live preview URL, desktop screenshots, and summaries instead of file paths, and "ship" publishes. Use for /afk, /afk off, or when the user says they are on their phone or away from the computer.
---

# afk

The user is working from a phone. They cannot open files, a terminal, an IDE, or a desktop browser, so everything needed to judge the work must arrive in the conversation: a URL to the live app, screenshots for desktop rendering, and summaries instead of file references. Apply this contract for the rest of the session.

The contract is harness and stack agnostic. Claude Code and Codex are the preferred harnesses and get named tools, but every step states a fallback that works from any agent, and nothing below assumes a specific dev server, git host, or deploy platform: detect what the project uses and adapt.

## Activation

- Bare `/afk`: turn the mode on and run the preview bootstrap now, then reply with the live URL and a one-line ready message. Proving the preview works before the first task keeps the user from debugging it while real work waits.
- `/afk <task>`: same bootstrap, then start the task immediately under this contract.
- `/afk off`: do not reload the contract; follow "Leaving the mode" below.
- The mode lasts the whole session. After a context compaction or a long gap, keep applying it unless the user turned it off, and rerun the bootstrap when the work moves to a different project or worktree.

## Output shape

- Lead with the outcome in one or two sentences, then only the detail needed to decide the next step.
- Keep messages scannable on a phone screen: no tables wider than three columns, no code blocks longer than about ten lines unless the user asks for code.
- Never point to a file path or command output as the answer; state the relevant content directly in the message.

## Dictated input

Mobile prompts often arrive by voice dictation, so expect transcription artifacts: homophones ("get" for "git", "cash" for "cache"), mangled identifiers and package names, missing punctuation, and run-on phrasing. Read for intent: map a garbled term to the nearest real file, branch, command, or dependency in this project, and note the interpretation in passing ("reading that as `pnpm lint`") so a wrong guess is caught at a glance. Ask only when plausible readings lead to materially different work; destructive actions always get the interpretation confirmed first.

## Live preview server

Every update should carry a URL where the current state of the app runs, reachable from the phone over Tailscale. The user taps it to interact with the live app, so it has to point at the code this session is editing, not another checkout.

Two conditions end this section before it starts, and each is one line in the update rather than a retry loop: the project renders no UI (CLI tool, library, dotfiles, script), so there is nothing to preview; or Tailscale is absent or logged out on this machine (`command -v tailscale`, then `tailscale status`), so the work continues without a preview URL.

- Resolve the hostname once per session with `tailscale status --json | jq -r '.CertDomains[0] // empty'`. A value there is the FQDN without a trailing dot and doubles as proof that the tailnet has HTTPS certificates enabled. Empty means they are off, and `tailscale serve --https=...` would then block waiting for a human to approve the feature in the admin console: fall back to `tailscale serve --bg --http=<port> <port>`, take the hostname from `.Self.DNSName` minus its trailing dot, and mention that plain HTTP is not a secure context, so service workers, clipboard, and crypto APIs stay unavailable in the preview.
- Detect the stack rather than assuming one: take the dev command, port, and package manager from the project itself (manifest scripts, lockfile, framework CLI).
- Main checkout: check whether the dev server answers on its usual port (`curl -sf`). If it is down, or the process owning the port does not run from this project directory (find the pid with `lsof -i :<port>`, then check its cwd), restart it in the background from the project root.
- Worktree: never reuse the main checkout's server, it serves different code. Start a dedicated server inside the worktree on a free port so both run side by side.
- Expose the port with `tailscale serve --bg <port>` on the default listener, or `tailscale serve --bg --https=<listener> <port>` on any free port when 443 is taken. Serve accepts any port. Run `tailscale serve status` first, since it prints the live URLs: reuse a mapping that already points at the right port, and never reset or repoint one this session did not create, it may belong to another service.
- If the framework blocks cross-origin dev access, wire the hostname in without committing it: Next.js reads `allowedDevOrigins` from `next.config`, which can take the value from an env variable; Vite accepts `server.allowedHosts` or the `__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS` env variable directly.
- Label the URL with what it serves (branch or worktree name) whenever more than one checkout is live, so the user never reviews stale code.
- When the session or worktree ends, turn off only the listeners this session added, for example `tailscale serve --https=8443 off`.

The tailnet URL renders with the phone's viewport: it is for interacting with the live app, not for judging desktop layout. Desktop rendering is what the screenshots below are for.

## Close every update

End each unit of work with this sequence, skipping only lines that do not apply:

1. **Verification**: run the project's checks (types, lint, tests) and report pass or fail with the command used.
2. **Diff summary**: one line per changed file as `path:line, resulting behavior`. This replaces a diff viewer on mobile, so describe behavior, not mechanics.
3. **Links**: one compact block carrying the live preview URL when there is one, plus the PR or MR, the deploy preview from whatever platform the project uses (Vercel, Cloudflare, Netlify, or other), and CI status when they exist.
4. **Desktop screenshots**: when the change can affect rendered UI, send them here, as the closing attachment of the update (spec below).
5. **Next step**: finish with a closed question offering the likely next actions (continue, adjust, ship, stop). Use the harness's closed-question prompt when it has one (AskUserQuestion in Claude Code); otherwise end with a short numbered list answerable with one word. Tapping or dictating one word beats typing sentences on a phone.

## Desktop screenshots

The user needs pages exactly as they render on a desktop, including layouts that would break or reflow on a phone. A phone browser cannot show this; a pinned desktop viewport can.

- Viewport 1440x900, full-page capture, one image per affected route or state.
- Never use a mobile viewport or let the page adapt to a small width; exact desktop rendering is the point.
- Capture against this session's dev server (the same one behind the live preview URL), driving it with whatever browser automation the environment offers (agent-browser skill, Playwright, or another headless browser).
- Save images to the session scratch or temp directory, never the repository, and send them into the conversation with the harness's attachment tool (SendUserFile in Claude Code). Without one, serve the directory over the tailnet and send per-image links: `tailscale serve` refuses filesystem paths on the macOS app builds, so run a throwaway static server in the screenshot directory (`python3 -m http.server <port>`) and expose that port instead.

## Ship trigger

"ship", alone or with extra notes, is the explicit ask that the standing commit boundary requires. It authorizes exactly three steps and nothing else:

1. Commit the session's changes following the repository's commit convention.
2. Push and open the request with the CLI matching the origin remote: `git push -u origin HEAD && gh pr create --fill` on GitHub, `glab mr create --fill --yes` on GitLab, which pushes the branch itself. With neither installed, push and reply with the host's compare URL (`<repo>/compare/<base>...<head>?expand=1` on GitHub, `<repo>/-/merge_requests/new?merge_request%5Bsource_branch%5D=<branch>` on GitLab) so one tap opens the form.
3. Reply with the link and a one-line summary.

Ship covers only this session's work, in the checkout the current turn is acting in; name that checkout when more than one is live. Never merge, never force-push; anything beyond commit, push, and open request needs its own ask. A clean "ship" is the one publishing action that skips confirmation, because confirming it would cost the round trip the word exists to save. Echo the scope back and wait when it arrives inside garbled or fragmentary dictation, where "don't ship yet" can lose its first two words.

## Leaving the mode

Leave on `/afk off`, or when the user says they are back at a desktop ("back at my desk", "back on the Mac"): drop this contract, return to normal output, and turn off only the tailscale serve listeners this session added. Leave dev servers running; they cost nothing locally and the user may return.
