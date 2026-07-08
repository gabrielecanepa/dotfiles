---
description: 'Use when writing or editing TypeScript (.ts/.tsx). Enforces the language-level idioms shared across projects: guard clauses, arrow functions, interface over type, inline type imports, alias imports, and the framework-docs-first research rule. React/JSX-specific rules live in react.instructions.md.'
applyTo: '**/*.ts, **/*.tsx'
paths:
  - '**/*.ts'
  - '**/*.tsx'
---

# TypeScript

Language-level idioms for any TypeScript file. React and JSX rules live in `react.instructions.md` (it also loads on `.tsx`). These are **rules, not config**: each repo enforces them with its own engine (oxlint, Biome, ESLint) and its own values; never globalize or rewrite a linter config to match. Honor the repo's existing config; where it is silent, follow these.

## Idioms

- **Guard clauses.** Return early; never `else`/`else if` after a `return`.
- **Arrow functions** assigned to `const`; no `function` keyword. Default-exported pages/layouts are named arrows: `const Page = () => {}; export default Page`.
- **`interface`** over `type` for object shapes.
- **No `.forEach`.** Use `for...of`, `map`, or `reduce`.
- **Inline type imports**: `import { type Foo }`, not `import type { Foo }`.
- **Imports.** No parent-relative imports (`../**`); use path aliases (`@/`, `~/`). Same-directory imports (`./`) only within one module: a folder whose barrel (`index`) is the sole public entry, whose files import each other by `./`. Across separate modules (siblings that are each their own unit, no shared barrel) use the alias, even when they sit in the same folder. So `features/user-profile/index.tsx` imports `./overview` (same module), but `features/user-notes.tsx` imports `@/components/features/chat-status`, not `./chat-status` (separate components).
- **kebab-case filenames.**
- **Omit inferrable types**: no return-type or variable annotations the compiler infers.
- `??` over `||` for default fallbacks.
- `async`/`await` only; no `.then()` chains.
- ESM only; no `require`/`module.exports`.

## Framework docs first

Before framework work (Next.js, React, an ORM, any library), read the installed version's docs over training-data memory, which lags the installed version: prefer bundled docs when present (e.g. `node_modules/<pkg>/dist/docs/`), else the `context7-mcp` skill (see AGENTS.md skill routing). State the version you targeted when a docs finding drove a non-obvious choice.
