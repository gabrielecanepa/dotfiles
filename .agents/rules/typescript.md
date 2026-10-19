---
description: "Use when writing or editing TypeScript files: guard clauses, arrow functions, interface over type, inline type and alias imports, exhaustive unions, typed catch."
applyTo: "**/*.ts, **/*.tsx, **/*.mts, **/*.cts"
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
---

# TypeScript

Language-level rules for all TypeScript files.

Follow the repository's existing configuration where it defines a rule. Apply the rules below where that configuration is silent.

## Idioms

- Return early with guard clauses; never `else` or `else if` after a `return`.
- Use arrow functions assigned to `const` unless a function declaration is required.
- Use `interface` over `type` for object shapes.
- Use `for...of` for iteration, `map` for transformation, and `reduce` for accumulation; never `.forEach`.
- Use kebab-case filenames unless the framework requires another name.
- Omit redundant type annotations; add them when inference does not express the intended type or contract.

## Imports

- Use configured path aliases for imports across modules.
- Use relative imports within a module or when no suitable alias exists.
- Import types inline: `import { type Foo }`, not `import type { Foo }`.
- Use ESM unless an existing runtime or `.cts` target requires CommonJS.

## Safety

- End a `switch` over a closed union with a `never` check in `default`, so adding a member fails to compile.
- For a lookup table that must cover every union member, use `satisfies Record<Union, T>`.
- Treat caught values as `unknown` and narrow them before use.
- Never use `catch (e: any)` or an empty catch block.
- Throw `Error` instances, not strings or other values.
- Use `async`/`await` only; no `.then()` chains.
- Use `??` when only `null` and `undefined` should trigger a fallback.

## Framework docs first

- Before using a framework or library API, check documentation for the installed version.
- Prefer bundled docs when present (`node_modules/<pkg>/dist/docs/`), else the `context7` MCP.
- When a docs finding drives a non-obvious choice, state the version you targeted.
