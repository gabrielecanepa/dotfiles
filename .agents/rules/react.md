---
description: "Use for React components (.jsx/.tsx): props, composition, JSX, state, effects, layer boundaries, and version-matched Next.js APIs."
applyTo: "**/*.jsx, **/*.tsx"
paths:
  - "**/*.jsx"
  - "**/*.tsx"
---

# React

TS idioms: `typescript.md`. Examples: `~/.agents/references/react-examples.md`.

## Skills and performance

- When writing React or Next.js code, apply `vercel-react-best-practices` by priority and re-check before finishing.
- When designing a non-trivial component, run `vercel-composition-patterns` first.
- When a project lacks either Vercel skill, ask to install it with the command in the reference.
- When a list can pass a few hundred rows, window it with `@tanstack/react-virtual` or `react-window`.
- When rows have hover-only controls, keep each row's first and last focusable controls mounted.
- When claiming a performance win, measure before and after with the React Profiler.

## Component props

- For prop-forwarding components, derive props from the target with `React.ComponentProps` and add the component's own props.
- When forwarding DOM props, merge `className` with `cn(...)` and spread the remaining props onto the target element.
- When a provider only wraps `children`, type it as `React.PropsWithChildren<{ ... }>` without merge or spread.
- Reference React types through the global `React` namespace; never import React or its types.

## Component design

- Choose composition by pressure per the reference: props, then slots or compound components, then context.
- Use `{cond && <El />}` for one branch and a ternary for two; the left side of `&&` must be a boolean.
- Use `<>...</>` unless the fragment needs a `key`.
- Read props directly; copy one into state only to seed the first render, named `defaultX` or `initialX`.
- Outside lists, use `key={id}` only when a new identity must reset the subtree.

## State and effects

- When a value belongs to a route or entity, store the owner identity and derive activity; never remount or sync it in an Effect.
- Key mapped elements by a stable id; use `key={index}` only for a static list that never changes order or length.
- Use Effects only to synchronize external systems; interactions stay in handlers.
- Match Effect dependencies to every reactive value read; never suppress `exhaustive-deps`.
- Keep renders pure and updates immutable; never read randomness, clocks, browser globals, or refs during render.

## Async and boundaries

- When React Compiler is on, do not hand-add `useMemo`, `useCallback`, or `React.memo`.
- When a client fetch fires on rapid input, abort the prior request with an `AbortController`, or use a data library that cancels.
- When an effect opens a listener, timer, subscription, or socket, return a cleanup that tears it down.
- For async user actions, show pending and error UI, block duplicate submission, and guard late continuations.
- Pass only minimal, serializable, non-sensitive data or Server Actions across the RSC boundary; keep Client Components narrow.
- Treat RSC data placed in client context as a snapshot with a defined freshness path.
- Sanitize dynamic HTML and allowlist schemes for dynamic `href` and `src`.

## State management

Keep state at the lowest level that works. Escalate for measured re-renders, deep prop drilling, or interdependent state.

1. Keep `useState` or `useReducer` where it renders; derive during render instead of mirroring state.
2. Lift to the nearest common owner and pass props; try composition before context.
3. Keep fetched data in TanStack Query, SWR, or RSC props, never copied into a client store.
4. Make a stateful provider render `{children}` it did not create; never hold hot state where the subtree is created.
5. Split context by change frequency and by state versus actions per the reference.
6. Use a selector-backed store last; adding a state library to a project without one is a decision to flag.

## Layers and Next.js placement

- App code imports features; features import shared code; shared `ui/`, `lib/`, `hooks/`, and `icons/` never import feature or app code.
- Keep a module in `ui/` only if it could ship in a generic library; once domain-bound it moves to `features/<domain>/`.
- In Next.js, keep framework-owned files in `app/`; application components and helpers belong in shared layers.
- In Next.js, define pages and layouts as named arrow functions, then default-export them.
- Before using version-specific Next.js APIs from the reference, confirm support in the installed version's docs.
- With Cache Components on, mark shared reads with `'use cache'`, set `cacheLife` and `cacheTag`, and `updateTag` affected tags.
- When calling a Server Action from a client event handler, use `startTransition`; apply `useOptimistic` in the same transition.
