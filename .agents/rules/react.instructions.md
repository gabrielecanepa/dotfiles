---
description: 'Use when writing or editing React components (.jsx/.tsx). Enforces prop forwarding, composition over boolean props, JSX, state, and key correctness idioms, the shared->features->app layer boundary, and Next.js app/ placement. Routes to the React performance and composition skills. Language-level TS idioms live in typescript.instructions.md.'
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

## Component props

Every component forwards the props of the element it renders.

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
- **Split context by change-frequency.** Every consumer of a context re-renders on any change to its value, whichever field it reads. Keep high-churn state out of a wide provider: split into narrow contexts, or back a hot store with an external store subscribed via `useSyncExternalStore`. The Compiler does not fix whole-value subscription.

## Layer boundaries

Dependencies flow **shared -> features -> app**. Shared layers (`ui/`, `lib/`, `hooks/`, `icons/`) stay domain-free and must not import from feature, app, or action code. A module belongs in `ui/` only if it could ship in a generic component library; the moment it binds to the domain it moves to `features/<domain>/`. Per-repo lint (`no-restricted-imports` or equivalent) enforces this; the boundary holds even where it does not.

## Next.js `app/` placement

In a Next.js project, `src/app/` (or `app/`) holds **only** Next.js framework files. Every other module (catalog/view components, `params.ts`, hooks, helpers, types) lives in the matching shared layer (`@/components`, `@/lib`, `@/hooks`, ...), never colocated in `app/`. A `page.tsx` imports its slices; it does not sit beside ad-hoc `.tsx`/`.ts` modules.

The framework files allowed in `app/` (Next.js 16): routing (`page`, `layout`, `loading`, `error`, `global-error`, `not-found`, `forbidden`, `unauthorized`, `default`, `template`, `route`), metadata routes (`sitemap`, `robots`, `manifest`), metadata images (`favicon`, `icon`, `apple-icon`, `opengraph-image`, `twitter-image`), and `*.css`. Anything not on this list does not belong in `app/`.
