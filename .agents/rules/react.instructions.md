---
description: 'Use when writing or editing React components (.jsx/.tsx). Enforces prop forwarding, composition over boolean props, JSX, state, and key correctness idioms, the shared->features->app layer boundary, Next.js app/ placement, and 16.3+ APIs. Routes to the React performance and composition skills. Language-level TS idioms live in typescript.instructions.md.'
applyTo: '**/*.jsx, **/*.tsx'
paths:
  - '**/*.jsx'
  - '**/*.tsx'
---

# React

For `.tsx` files, `typescript.instructions.md` also loads; it owns the language-level idioms (guard clauses, arrow functions, imports). This file owns the React, JSX, and component-architecture rules.

## Skills

- **Any React/Next.js code** → `vercel-react-best-practices` is the performance bar. Apply it by priority (CRITICAL > HIGH > MEDIUM > LOW) and re-check against it before declaring component work done.
- **Any non-trivial component design** → run `vercel-composition-patterns` first (compound components, slots, context providers, render props).
- **Animation work** → `motion.instructions.md` owns the animation rules and skill routing.
- Load only the relevant `rules/*.md` from Vercel skills. Do not load a compiled `AGENTS.md` unless the task genuinely needs the full corpus.
- **Long lists** → the perf skill stops at `content-visibility`; past a few hundred rows that is not enough. Windowing (render only visible rows) is a hard requirement, via `@tanstack/react-virtual` or `react-window`.
- **Dense rows** → render hover-only controls on hover or focus; keep each row's first and last focusable controls mounted so keyboard and screen-reader users can still reach the row.
- **Perf claims** → measure before and after (React DevTools Profiler or equivalent) before calling a change an optimization; an unmeasured one is a refactor, not a win.

## Component props

Components that transparently render a DOM element or child component forward that target's props.

### The rule

Type props as `React.ComponentProps<...>` intersected with the component's own props. Destructure `className` and `...props`, merge with `cn(...)`, and spread onto the underlying element. Reference React types through the global `React` namespace; never import React or its types.

- **DOM element** (`div`, `button`, ...) → `React.ComponentProps<'div'>`.
- **Another component** → `React.ComponentProps<typeof Child>`, spread onto that child.
- **Provider with `children` and no underlying element** → `React.PropsWithChildren<{ ... }>`, no merge/spread.

Spread rest props onto the root element or child component they configure; a pure provider has neither.

### Examples

DOM root: merge `className`, spread the rest.

```tsx
const ChatFilters = ({
  className,
  counts,
  type,
  unrepliedCount,
  ...props
}: React.ComponentProps<'div'> & {
  counts: Record<string, number>
  type: ChatType
  unrepliedCount: number
}) => (
  <div className={cn('flex flex-col gap-2.5 border-b p-3', className)} {...props}>
    {/* ... */}
  </div>
)
```

A pure provider takes `React.PropsWithChildren`; it has no element to receive merged props.

```tsx
export const DashboardProvider = ({
  advisors,
  children,
  sidebarOpen,
  user,
}: React.PropsWithChildren<{
  advisors: Advisor[]
  sidebarOpen: boolean
  user: AuthInfo
}>) => (
  <AuthProvider user={user}>
    <AdvisorsProvider advisors={advisors}>
      <SidebarProvider defaultOpen={sidebarOpen}>{children}</SidebarProvider>
    </AdvisorsProvider>
  </AuthProvider>
)
```

## Component design

- **Choose composition by pressure.** Start with props and local state. Use slots or compound components when structural options proliferate or allow invalid combinations; intrinsic flags and finite visual variants stay props. Add context only for deep or non-contiguous consumers, or when a subtree must swap state or data sources. A third structural boolean triggers API review, not an automatic rewrite.
- **JSX.** `{cond && <El />}` for one branch, a ternary for two; the left side of `&&` must be a real boolean (`items.length > 0 &&`), a number leaks a literal `0` into the output. `<>...</>` over `<Fragment>`. Named imports for hooks and values (`useState`, `use`); never import `React` itself in any form, its types come from the global namespace (see the rule above).
- **Props are not initial state.** Read props directly; copy one into state only to seed the first render and name it `defaultX`/`initialX`. Use `key={id}` only when a new identity must reset every descendant. When one value belongs to a route or entity, store that owner identity and derive whether it remains active; do not remount or sync it in an Effect.
- **Stable keys.** Key mapped elements by a stable id from the data. `key={index}` only for a static list that never reorders, inserts, or deletes; it corrupts per-item state and inputs the moment the list changes.
- **Effects stay honest.** Effects synchronize external systems; interactions stay in handlers. Dependencies match every reactive value read; never suppress `exhaustive-deps`. Use `[]` only when none are read.
- **Keep renders pure and updates immutable.** Never mutate props or state or read randomness, clocks, browser-only globals, or refs during render. Use immutable copies, `useId`, lazy state, handlers, or `useSyncExternalStore` with a server snapshot.
- **No manual memoization under React Compiler.** When React Compiler is enabled, do not hand-add `useMemo`, `useCallback`, or `React.memo`; the compiler memoizes. (Only when the compiler is on.)
- **Cancel superseded requests.** For client fetches that fire on rapid input (search-as-you-type, filters, quick nav), pass an `AbortController` signal and abort the prior request so a slow earlier response can't overwrite a newer one. Prefer a data library that cancels for you (TanStack Query, `use`+RSC) over hand-rolled effects. Any effect that opens a listener, timer, subscription, or socket returns a cleanup that tears down exactly what it set up.
- **Async actions own their state.** User-triggered promises expose pending and error UI, block duplicate submission while pending, and abort or guard continuations that may outlive the component.
- **Respect RSC boundaries.** Pass only minimal, serializable, non-sensitive data or Server Actions and keep Client Components narrow. Data passed from an RSC into client context is a snapshot, not live server state: name its initial role and define freshness through navigation, invalidation, refresh, or a supported client source. Sanitize dynamic HTML and allowlist schemes for dynamic `href` and `src`.

## State management

Place state at the lowest level that works and escalate one step at a time, only under real pressure: measured re-renders, prop drilling through 3+ levels, or interdependent state.

1. **Local state.** `useState`/`useReducer` in the component that renders it. Derive during render instead of mirroring one state into another; never sync copies in an Effect.
2. **Lift to the nearest common owner** and pass props; reach for composition before context (the pressure rule above).
3. **Server state stays in the data layer.** Fetched data belongs to TanStack Query, SWR, or RSC props; a client store holding a copy is a second source of truth.
4. **Providers are not parents.** A stateful provider renders `{children}` it did not create, so its own state changes reuse the same child elements and skip subtree reconciliation (the `DashboardProvider` example above follows this shape). Never hold hot state in a component that also creates the subtree it renders.
5. **Split context by change-frequency and by state versus actions.** Every consumer of a context re-renders on any change to its value, whichever field it reads. Keep high-churn state out of a wide provider: split into narrow contexts, and expose actions through their own context or hook with stable identity (functional `setState`, `useEffectEvent`, or the perf skill's `advanced-event-handler-refs` pattern) so action-only consumers never re-render. This overrides the composition skill's single `{ state, actions, meta }` context shape once hot state or action-only consumers appear. The Compiler does not fix whole-value subscription or unstable action identity.
6. **Selector-backed store last.** When many consumers read different slices of one hot object, subscribe through `useSyncExternalStore` with selectors, or the store library the project already uses. Adding a state library to a project that has none is an architecture decision to flag, not a default.

## Layer boundaries

Dependencies flow **shared -> features -> app**. Shared layers (`ui/`, `lib/`, `hooks/`, `icons/`) stay domain-free and must not import from feature, app, or action code. A module belongs in `ui/` only if it could ship in a generic component library; the moment it binds to the domain it moves to `features/<domain>/`. Per-repo lint (`no-restricted-imports` or equivalent) enforces this; the boundary holds even where it does not.

## Next.js `app/` placement

In a Next.js project, `src/app/` (or `app/`) holds **only** Next.js framework files. Every other module (catalog/view components, `params.ts`, hooks, helpers, types) lives in the matching shared layer (`@/components`, `@/lib`, `@/hooks`, ...), never colocated in `app/`. A `page.tsx` imports its slices; it does not sit beside ad-hoc `.tsx`/`.ts` modules.

The framework files allowed in `app/` (Next.js 16): routing (`page`, `layout`, `loading`, `error`, `global-error`, `not-found`, `forbidden`, `unauthorized`, `default`, `template`, `route`), metadata routes (`sitemap`, `robots`, `manifest`), metadata images (`favicon`, `icon`, `apple-icon`, `opengraph-image`, `twitter-image`), and `*.css`. Anything not on this list does not belong in `app/`.

## Next.js APIs (16.3+)

- **Root params.** Read root-level dynamic params (`[lang]`) through the async getters of `next/root-params` (`await lang()`) in Server Components only; Client Components get them as props from a server parent.
- **Error boundaries.** Use `catchError` from `next/error` for custom boundaries (the fallback is a Client Component): it passes `notFound`/`redirect` through and its `retry()` re-fetches the boundary's children.
- **Cache Components.** With `cacheComponents: true` and `partialPrefetching: true` in `next.config.ts` (both stable in 16.3), mark shared reads with `'use cache'` (arguments join the cache key), set freshness with `cacheLife`, and label entries with `cacheTag`. A mutating Server Action calls `updateTag` from `next/cache` for every tag whose view the write changes, not only the entity's own tag.
- **Prefetching.** A visible `<Link>` prefetches one shared shell per route by default; add `prefetch={true}` only where URL-specific `'use cache'` content must be ready at click, since it can invoke the server as the link enters the viewport.
- **Suspense settle order.** Nest a lower section's boundary inside the boundary above it so streamed sections settle top-down without serializing their data fetches.
- **Optimistic mutations.** Start Server Actions inside `startTransition` and apply `useOptimistic` updates in the same transition; queue repeated mutations in order with `useActionState`. `experimental.useOffline` is not production-ready; do not enable it by default.
