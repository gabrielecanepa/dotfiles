---
description: "Use when writing or editing Node.js server-side code: APIs, services, CLIs, scripts, workers. Runtime discipline for the event loop, streams, errors, shutdown, config, testing, and packaging."
applyTo: "**/*.cjs, **/*.mjs, **/*.server.{ts,js}, **/api/**/*.{ts,js,mts,cts}, **/jobs/**/*.{ts,js,mts,cts}, **/scripts/**/*.{ts,js,mts,cts}, **/server/**/*.{ts,js,mts,cts}, **/workers/**/*.{ts,js,mts,cts}"
paths:
  - "**/*.cjs"
  - "**/*.mjs"
  - "**/*.server.{ts,js}"
  - "**/api/**/*.{ts,js,mts,cts}"
  - "**/jobs/**/*.{ts,js,mts,cts}"
  - "**/scripts/**/*.{ts,js,mts,cts}"
  - "**/server/**/*.{ts,js,mts,cts}"
  - "**/workers/**/*.{ts,js,mts,cts}"
---

# Node.js

Runtime rules for Node server code. Read by intent outside the scoped paths. TS idioms: `typescript.md`.

For detail, use an installed Node skill or version-matched Node.js docs.

## Event loop and concurrency

- Keep blocking work out of request handlers; use asynchronous I/O and workers for CPU-heavy work.
- For sustained CPU work, use the project's existing worker pool, or justify a new pool dependency.
- Bound concurrency with an existing utility or worker loop; never run unbounded `Promise.all` over large inputs.
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

- For Node.js system errors, narrow the caught value and check its `code` rather than relying on the error class.
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

- When the target runtime supports it, load env with `--env-file` or `process.loadEnvFile()` instead of adding dotenv.
- Validate config at boot with a schema and exit non-zero on failure.
- For application-specific behavior, use an explicit env var rather than overloading `NODE_ENV`.

## Testing and diagnostics

- Default to `node:test` with `node --test` and mock with `t.mock.fn()` or `t.mock.method()`; the repo's declared runner still wins.
- Register event listeners before triggering emits in tests; emit-before-listen causes flaky hangs.
- Debug hung processes and tests with `why-is-node-running`; fix teardown, never lengthen timeouts.
- Profile CPU with `--cpu-prof`, benchmark HTTP with `autocannon` before and after, and hunt leaks with `--inspect` heap snapshots.

## Modules and packaging

- Prefix builtins with `node:` and use explicit file extensions in ESM imports.
- When the target runtime supports them, use `import.meta.dirname` and JSON imports with `with { type: 'json' }`.
- On type-stripping targets (Node 22.6+), use erasable TS syntax only: no enums, namespaces, or parameter properties.
- With type stripping, set `verbatimModuleSyntax` and typecheck separately with `tsc --noEmit`.

## Auth

- For user-facing OAuth authorization, use authorization code with PKCE (S256); never the implicit flow or tokens in URL fragments.
- Validate redirect URIs against an allowlist.
- For JWT credentials, validate the signature, issuer, audience, expiry, and required subject.
- For third-party JWTs, use JWKS and allowlist RS256 or ES256; never accept HS256.
- For browser sessions, keep tokens in HttpOnly, Secure, SameSite cookies.
- When the issuer supports rotation, rotate refresh tokens on use; rate-limit token endpoints.
