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
- **No parent-relative imports** (`../**`). Use path aliases (`@/`, `~/`).
- **kebab-case filenames.**
- **Omit inferrable types**: no return-type or variable annotations the compiler infers.
- `string[]`, not `Array<string>`.
- `??` over `||` for default fallbacks.
- Template literals over string concatenation.
- `async`/`await` only; no `.then()` chains.
- ESM only; no `require`/`module.exports`.
- `const` over `let` for bindings that never reassign.
- `===`/`!==`, never `==`/`!=`.

## Framework docs first

Before framework work (Next.js, React, an ORM, any library), read the installed version's docs over training-data memory, which lags the installed version: prefer bundled docs when present (e.g. `node_modules/<pkg>/dist/docs/`), else the `context7-mcp` skill (see AGENTS.md skill routing). State the version you targeted when a docs finding drove a non-obvious choice.
