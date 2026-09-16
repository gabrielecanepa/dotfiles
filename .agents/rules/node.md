---
description: 'Use when writing or editing Node.js server-side code: APIs, services, CLIs, scripts, workers. Runtime discipline for the event loop, streams, errors, shutdown, config, testing, and packaging.'
applyTo: '**/*.cjs, **/*.mjs, **/*.server.{ts,js}, **/api/**/*.{ts,js,mts,cts}, **/jobs/**/*.{ts,js,mts,cts}, **/scripts/**/*.{ts,js,mts,cts}, **/server/**/*.{ts,js,mts,cts}, **/workers/**/*.{ts,js,mts,cts}'
paths:
  - '**/*.cjs'
  - '**/*.mjs'
  - '**/*.server.{ts,js}'
  - '**/api/**/*.{ts,js,mts,cts}'
  - '**/jobs/**/*.{ts,js,mts,cts}'
  - '**/scripts/**/*.{ts,js,mts,cts}'
  - '**/server/**/*.{ts,js,mts,cts}'
  - '**/workers/**/*.{ts,js,mts,cts}'
---

# Node.js

Runtime rules for Node server-side work. For Node work outside these paths, open this file by intent. TS idioms live in `typescript.md`.

For depth on any topic, run `npx skills use mcollina/skills@node`.

## Event loop and concurrency

- Never run CPU-heavy or synchronous work on the event loop; use asynchronous built-ins and `node:worker_threads`.
- For sustained CPU work, use the project's existing worker pool, or justify a new pool dependency.
- Bound concurrency with the project's existing utility or a small worker loop; never run unbounded `Promise.all` over large inputs.
- Add `p-limit` or `p-map` only when their semantics justify a dependency.
- Use `Promise.allSettled` when partial failure is acceptable and `Promise.all` only for all-or-nothing independent work.
- Cancel long-running operations with `AbortController` and build timeouts from `AbortSignal.timeout()`.
- Never make a constructor async; use a static async factory.

## Streams

- Use `await pipeline()` from `node:stream/promises`, never `.pipe()`.
- Respect backpressure: check the `write()` return value and `await once(stream, 'drain')` before writing more.
- Consume with `for await...of`, create from iterables with `Readable.from()`, and collect with `node:stream/consumers`.
- Stream large files and responses instead of buffering them into memory.

## Errors and shutdown

- Check errors by their `code` property, not by class.
- Preserve chains with `new Error(msg, { cause })`; never swallow an error in an empty catch.
- Route fatal process errors into the application's existing graceful-shutdown path.
- Add a lifecycle package such as `close-with-grace` only when the project lacks one and the service needs it.
- Shut down in order: flag shutdown, fail health checks, drain in-flight requests, close resources in reverse-init order, force-exit after a timeout.

## Performance, caching, logging

- Bound every cache by size and expiry, preferring the project's cache.
- Add `lru-cache` or `async-cache-dedupe` only when their eviction or request-coalescing behavior is required.
- Pool database connections with explicit `max` and timeout settings.
- Log through the project's structured logger with request context, secret redaction, and an environment-controlled level.
- When a new logger is justified, prefer `pino`. Never log credentials or tokens.

## Config and env

- Load env with `--env-file` or `process.loadEnvFile()`, not dotenv.
- Validate config at boot with a schema and exit non-zero on failure.
- Avoid branching on `NODE_ENV`; define one explicit env var per concern.

## Testing and diagnostics

- Default to `node:test` with `node --test` and mock with `t.mock.fn()` or `t.mock.method()`; the repo's declared runner still wins.
- Register event listeners before triggering emits in tests; emit-before-listen causes flaky hangs.
- Debug hung processes and tests with `why-is-node-running`; fix teardown, never lengthen timeouts.
- Profile CPU with `--cpu-prof`, benchmark HTTP with `autocannon` before and after, and hunt leaks with `--inspect` heap snapshots.

## Modules and packaging

- Prefix builtins with `node:` and use explicit file extensions in ESM imports.
- Use `import.meta.dirname` over `__dirname` shims and import JSON `with { type: 'json' }`.
- On type-stripping targets (Node 22.6+), use erasable TS syntax only: no enums, namespaces, or parameter properties.
- With type stripping, set `verbatimModuleSyntax` and typecheck separately with `tsc --noEmit`.

## Auth

- When touching OAuth, use authorization code with PKCE (S256) only; never the implicit flow or tokens in URL fragments.
- Validate redirect URIs against an allowlist.
- Validate `iss`, `aud`, `exp`, and `sub` on every JWT; use RS256 or ES256 with JWKS for third-party tokens, never HS256.
- Store tokens in HttpOnly, Secure, SameSite cookies; rotate refresh tokens on each use; rate-limit token endpoints.
