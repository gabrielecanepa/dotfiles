---
description: 'Use when writing or editing React components (.jsx/.tsx). Enforces prop forwarding, composition over boolean props, JSX idioms, the shared->features->app layer boundary, and Next.js app/ placement. Routes to the React performance and composition skills. Language-level TS idioms live in typescript.instructions.md.'
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

## Component props

Every component, exported or not, must accept the props of the element it renders, merge them, and spread them. A component that hardcodes `className` and drops the rest is unstylable and unextendable by its callers.

### The rule

Type the props as `ComponentProps<...>` (via `import { type ComponentProps } from 'react'`, per the named-imports rule) intersected with the component's own props, destructure `className` and `...props`, merge `className` with `cn(...)`, and spread `...props` onto the underlying element.

- **DOM element** (`div`, `button`, ...) → `ComponentProps<'div'>`.
- **Another component** → `ComponentProps<typeof Child>`, spread onto that child.
- **Provider with `children` and no underlying element** → `PropsWithChildren<{ ... }>`, no merge/spread.

The underlying element is whichever single element the rest props belong on: the root DOM node, or the one child component the wrapper exists to configure. A provider that only nests other providers has none.

### Examples

DOM root: merge `className`, spread the rest.

```tsx
const ChatFilters = ({
  className,
  counts,
  type,
  unrepliedCount,
  ...props
}: ComponentProps<'div'> & {
  counts: Record<string, number>
  type: ChatType
  unrepliedCount: number
}) => (
  <div className={cn('flex flex-col gap-2.5 border-b p-3', className)} {...props}>
    {/* ... */}
  </div>
)
```

A pure provider (only other providers, no DOM element) takes `React.PropsWithChildren`, no merge or spread. A wrapper around another component types as `ComponentProps<typeof Child>` and forwards the rest to that child; a wrapping provider with a DOM element under it still merges and spreads onto that element.

```tsx
export const DashboardProvider = ({
  advisors,
  children,
  sidebarOpen,
  user,
}: PropsWithChildren<{
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

- **Compose, don't configure.** Build with composition (compound components, slots, context providers) over boolean-prop configuration. A **third boolean prop** is the signal to restructure into compound components. Run `vercel-composition-patterns` for any non-trivial design.
- **JSX.** `{cond && <El />}` for one branch, a ternary for two; `<>...</>` over `<Fragment>`; named imports only (no default `React` import).
- **No manual memoization under React Compiler.** When React Compiler is enabled, do not hand-add `useMemo`, `useCallback`, or `React.memo`; the compiler memoizes. (Only when the compiler is on.)

## Layer boundaries

Dependencies flow **shared -> features -> app**. Shared layers (`ui/`, `lib/`, `hooks/`, `icons/`) stay domain-free and must not import from feature, app, or action code. A module belongs in `ui/` only if it could ship in a generic component library; the moment it binds to the domain it moves to `features/<domain>/`. Per-repo lint (`no-restricted-imports` or equivalent) enforces this; the boundary holds even where it does not.

## Next.js `app/` placement

In a Next.js project, `src/app/` (or `app/`) holds **only** Next.js framework files. Every other module (catalog/view components, `params.ts`, hooks, helpers, types) lives in the matching shared layer (`@/components`, `@/lib`, `@/hooks`, ...), never colocated in `app/`. A `page.tsx` imports its slices; it does not sit beside ad-hoc `.tsx`/`.ts` modules.

The framework files allowed in `app/` (Next.js 16): routing (`page`, `layout`, `loading`, `error`, `global-error`, `not-found`, `forbidden`, `unauthorized`, `default`, `template`, `route`), metadata routes (`sitemap`, `robots`, `manifest`), metadata images (`favicon`, `icon`, `apple-icon`, `opengraph-image`, `twitter-image`), and `*.css`. Anything not on this list does not belong in `app/`.
