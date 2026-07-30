---
description: 'Use when writing or editing Node.js server-side code: APIs, services, CLIs, scripts, workers. Node runtime discipline: event loop, streams and backpressure, error handling and shutdown, diagnostics, caching, logging, config, testing, packaging. Distilled from mcollina/skills. Language-level TS idioms live in typescript.instructions.md.'
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

Runtime rules for Node server-side work (APIs, services, CLIs, scripts, workers). For Node work outside these paths, open this file by intent (see the AGENTS.md skill routing). TS idioms live in `typescript.instructions.md`. Distilled from `mcollina/skills`; run `npx skills use mcollina/skills@node` for depth on any topic.

## Event loop and concurrency

- Never run CPU-heavy or synchronous work on the event loop. Use asynchronous built-ins and `node:worker_threads`; use the project's existing worker pool, or justify a new pool dependency for sustained workloads.
- Bound concurrency with the project's existing utility or a small worker loop. Add `p-limit` or `p-map` only when their semantics justify a dependency; never use unbounded `Promise.all` over large inputs.
- `Promise.allSettled` when partial failure is acceptable; `Promise.all` only for all-or-nothing independent work.
- Cancel long-running operations with `AbortController`; build timeouts from `AbortSignal.timeout()`.
- Never make constructors async; use a static async factory instead.

## Streams

- `await pipeline()` from `node:stream/promises`, never `.pipe()`; it propagates errors and guarantees cleanup.
- Respect backpressure: check the `write()` return value and `await once(stream, 'drain')` before writing more.
- Consume with `for await...of`; create from iterables with `Readable.from()`; collect via `node:stream/consumers`.
- Stream large files and responses instead of buffering them into memory.

## Errors and shutdown

- Check errors by `code` property, not by class; preserve chains with `new Error(msg, { cause })`; never swallow errors in empty catches.
- Route fatal process errors into the application's existing graceful-shutdown path. Add a lifecycle package such as `close-with-grace` only when the project lacks one and the service needs it.
- Shut down gracefully: flag shutdown, fail health checks, drain in-flight requests, close resources in reverse-init order, force-exit after a timeout.

## Performance, caching, logging

- Bound every cache by size and expiry. Prefer the project's cache; add `lru-cache` or `async-cache-dedupe` only when their eviction or request-coalescing behavior is required.
- Pool database connections with explicit `max` and timeout settings.
- Use the project's structured logger with request context, secret redaction, and an environment-controlled level. If a new logger is justified, prefer `pino`. Never log credentials or tokens.

## Config and env

- Load env with `--env-file`/`process.loadEnvFile()`, not dotenv; validate at boot with a schema and exit non-zero on failure.
- Avoid branching on `NODE_ENV`; define one explicit env var per concern.

## Testing and diagnostics

- Default to `node:test` (`node --test`); mock with `t.mock.fn()`/`t.mock.method()`. The repo's declared runner (vitest/jest) still wins.
- Register event listeners before triggering emits in tests; emit-before-listen causes flaky hangs.
- Debug hung processes and tests with `why-is-node-running`; fix teardown, never lengthen timeouts.
- Profile CPU with `--cpu-prof` and benchmark HTTP with `autocannon` before and after; hunt leaks with `--inspect` heap snapshots.

## Modules and packaging

- Prefix builtins with `node:`; explicit file extensions in ESM imports; `import.meta.dirname` over `__dirname` shims; import JSON `with { type: 'json' }`.
- For type-stripping targets (Node 22.6+): erasable TS syntax only (no enums, namespaces, or parameter properties), `verbatimModuleSyntax`, typecheck separately with `tsc --noEmit`.

## Auth (when touching OAuth/JWT)

- Authorization code + PKCE (S256) only; never the implicit flow or tokens in URL fragments; validate redirect URIs against an allowlist.
- Validate `iss`, `aud`, `exp`, and `sub` on every JWT; RS256/ES256 with JWKS for third-party tokens, never HS256.
- Store tokens in HttpOnly/Secure/SameSite cookies; rotate refresh tokens on each use; rate-limit token endpoints.
