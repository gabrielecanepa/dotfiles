# React examples and detail

Examples and reference detail behind `rules/react.md`. Read the section the current task needs.

## Prop forwarding

A component with a DOM root merges `className` and spreads the rest onto that root.

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

A pure provider takes `React.PropsWithChildren` and has no element to receive merged props.

It renders `{children}` it did not create, so its own state changes reuse the same child elements and skip subtree reconciliation.

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

## Composition pressure

- Start with props and local state.
- Move to slots or compound components when structural options proliferate or allow invalid combinations; intrinsic flags and finite visual variants stay props.
- Add context only for deep or non-contiguous consumers, or when a subtree must swap state or data sources.
- A third structural boolean triggers API review, not an automatic rewrite.

## Context splitting

Every consumer of a context re-renders on any change to its value, whichever field it reads.

React Compiler does not fix whole-value subscription or unstable action identity.

- Keep high-churn state out of a wide provider; split it into narrow contexts.
- Expose actions through their own context or hook with stable identity.
- Stable identity comes from functional `setState`, `useEffectEvent`, or the perf skill's `advanced-event-handler-refs` pattern.
- This overrides the composition skill's single `{ state, actions, meta }` context shape once hot state or action-only consumers appear.
- When many consumers read different slices of one hot object, subscribe through `useSyncExternalStore` with selectors or the project's store.

## Next.js `app/` framework files

Files allowed in `app/` on Next.js 16:

- Routing: `page`, `layout`, `loading`, `error`, `global-error`, `not-found`, `forbidden`, `unauthorized`, `default`, `template`, `route`.
- Metadata routes: `sitemap`, `robots`, `manifest`.
- Metadata images: `favicon`, `icon`, `apple-icon`, `opengraph-image`, `twitter-image`.
- `*.css`.

Anything not on this list lives in the matching shared layer (`@/components`, `@/lib`, `@/hooks`); a `page.tsx` imports its slices.

## Next.js 16.3+ API detail

- Root params: `next/root-params` exposes async getters (`await lang()`) for Server Components; Client Components receive them as props from a server parent.
- Error boundaries: `catchError` from `next/error` passes `notFound` and `redirect` through; `retry()` re-fetches the children.
- The `catchError` fallback is a Client Component.

## Cache Components and mutations

- Cache Components: `cacheComponents: true` and `partialPrefetching: true` in `next.config.ts` are stable in 16.3.
- `'use cache'` arguments join the cache key; `cacheLife` sets freshness; `cacheTag` labels entries.
- Invalidation: a mutating Server Action calls `updateTag` from `next/cache` for every tag whose view the write changes, not only the entity's own tag.

## Prefetching and streaming

- Prefetching: a visible `<Link>` prefetches one shared shell per route.
- `prefetch={true}` can invoke the server as the link enters the viewport; add it only where URL-specific cached content must be ready at click.
- Suspense: nest a lower section's boundary inside the boundary above it so streamed sections settle top-down without serializing their fetches.
- Optimistic mutations: start Server Actions inside `startTransition` and apply `useOptimistic` in the same transition.
- Queue repeated mutations in order with `useActionState`.
- `experimental.useOffline` is not production-ready; do not enable it by default.

## Vercel skills

- Install from the project root: `npx skills add vercel-labs/agent-skills --skill <name> --yes`.
- Load only the relevant `rules/*.md` from a Vercel skill; load its compiled `AGENTS.md` only when the task needs the full corpus.
