# Live preview server

The procedure behind the afk skill's live preview URL. Loaded when the afk bootstrap runs.

## Preconditions

- When the project renders no UI (CLI tool, library, dotfiles, script), say so in one line and skip the preview.
- When `command -v tailscale` fails or `tailscale status` reports logged out, say so in one line and continue without a preview URL.
- Never retry either condition in a loop.

## Hostname

- Resolve the hostname once per session with `tailscale status --json | jq -r '.CertDomains[0] // empty'`.
- A value there is the FQDN without a trailing dot and proves the tailnet has HTTPS certificates enabled.
- When it is empty, never run `tailscale serve --https=...`, because it blocks waiting for a human to approve the feature in the admin console.
- In that case run `tailscale serve --bg --http=<port> <port>` and take the hostname from `.Self.DNSName` minus its trailing dot.
- When serving plain HTTP, tell the user it is not a secure context, so service workers, clipboard, and crypto APIs stay unavailable in the preview.

## Dev server

- Detect the stack from the project itself: dev command, port, and package manager from manifest scripts, lockfile, or framework CLI.
- In the main checkout, check whether the dev server answers on its usual port with `curl -sf`.
- Find the process owning the port with `lsof -i :<port>`, then check its cwd.
- When the server is down, or that process does not run from this project directory, restart it in the background from the project root.
- In a worktree, never reuse the main checkout's server; start a dedicated server inside the worktree on a free port so both run side by side.
- When the framework blocks cross-origin dev access, wire the hostname in without committing it.
- Next.js reads `allowedDevOrigins` from `next.config`, which can take the value from an env variable.
- Vite accepts `server.allowedHosts` or the `__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS` env variable directly.

## Expose the port

1. Run `tailscale serve status` first; it prints the live URLs.
2. Reuse a mapping that already points at the right port.
3. Never reset or repoint a mapping this session did not create; it may belong to another service.
4. Expose with `tailscale serve --bg <port>` on the default listener, or `tailscale serve --bg --https=<listener> <port>` on a free port when 443 is taken.
5. Label the URL with what it serves (branch or worktree name) whenever more than one checkout is live.
6. When the session or worktree ends, turn off only the listeners this session added, for example `tailscale serve --https=8443 off`.

## Screenshot hosting fallback

- When the harness has no attachment tool, serve the screenshot directory over the tailnet and send per-image links.
- `tailscale serve` refuses filesystem paths on the macOS app builds, so run `python3 -m http.server <port>` in the screenshot directory and expose that port.
