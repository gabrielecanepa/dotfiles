---
description: 'Use when writing or editing TypeScript (.ts/.tsx): guard clauses, arrow functions, interface over type, inline type and alias imports, exhaustive unions, typed catch.'
applyTo: '**/*.ts, **/*.tsx'
paths:
  - '**/*.ts'
  - '**/*.tsx'
---

# TypeScript

Language-level idioms for any TypeScript file; React and JSX rules live in `react.md`.

Each repository enforces these with its own linter: honor the existing config, never rewrite one to match, and follow these where it is silent.

## Idioms

- Return early with guard clauses; never `else` or `else if` after a `return`.
- Write arrow functions assigned to `const`, never the `function` keyword.
- Default-export a page or layout as a named arrow: `const Page = () => {}; export default Page`.
- Use `interface` over `type` for object shapes.
- Use `for...of`, `map`, or `reduce`; never `.forEach`.
- Import types inline: `import { type Foo }`, not `import type { Foo }`.
- Name files in kebab-case.
- Omit types the compiler infers: no return-type or variable annotations.

## Imports

- Never import parent-relative (`../**`); use the path alias (`@/`, `~/`).
- Use `./` only inside one module: a folder whose barrel (`index`) is the sole public entry and whose files import each other.
- Across separate modules, use the alias even in the same folder: `user-notes.tsx` imports `@/components/features/chat-status`, not `./chat-status`.
- Use ESM only; no `require` or `module.exports`.

## Safety

- End a `switch` over a closed union with a `never` check in `default`, so adding a member fails to compile.
- Type lookup tables with `satisfies Record<Union, T>`.
- Type `catch` as `unknown` and narrow before use (`instanceof Error`, a guard); never `catch (e: any)`, an empty swallow, or a thrown non-`Error`.
- Use `async`/`await` only; no `.then()` chains.
- Use `??` over `||` for default fallbacks.

## Framework docs first

- Before framework work (Next.js, React, an ORM, any library), read the installed version's docs instead of training memory.
- Prefer bundled docs when present (`node_modules/<pkg>/dist/docs/`), else the `context7` MCP.
- Treat the version-matched docs block Next.js 16.3+ maintains via `next dev` as bundled docs.
- When a docs finding drives a non-obvious choice, state the version you targeted.
