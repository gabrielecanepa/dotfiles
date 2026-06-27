---
description: "Use when writing or editing React components (.jsx/.tsx). Enforces that every component accepts, merges, and spreads its underlying element's props so callers can style and extend it."
applyTo: '**/*.jsx, **/*.tsx'
paths:
  - '**/*.jsx'
  - '**/*.tsx'
---

# React Components

Every component, exported or not, must accept the props of the element it renders, merge them, and spread them. A component that hardcodes `className` and drops the rest is unstylable and unextendable by its callers.

## The rule

Type the props as `React.ComponentProps<...>` intersected with the component's own props, destructure `className` and `...props`, merge `className` with `cn(...)`, and spread `...props` onto the underlying element.

- **DOM element** (`div`, `button`, ...) → `React.ComponentProps<'div'>`.
- **Another component** → `React.ComponentProps<typeof Child>`, spread onto that child.
- **Provider with `children` and no underlying element** → `React.PropsWithChildren<{ ... }>`, no merge/spread.

The underlying element is whichever single element the rest props belong on: the root DOM node, or the one child component the wrapper exists to configure. A provider that only nests other providers has none.

## Examples

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

Underlying child component: forward the rest to it.

```tsx
const ChatList = ({
  chats,
  type,
  ...props
}: React.ComponentProps<typeof ChatListContent> & {
  chats: Chat[]
  type: ChatType
}) => (
  <Search includeMatches items={chats}>
    <ChatListContent type={type} {...props} />
  </Search>
)
```

A wrapping provider still has an underlying element underneath it.

```tsx
const ChatView = ({
  chats,
  className,
  defaultChat,
  type,
  ...props
}: React.ComponentProps<'div'> & {
  chats: Chat[]
  defaultChat?: { id: string; detail: ChatDetail | null }
  type: ChatType
}) => (
  <ChatProvider chats={chats}>
    <div className={cn('flex min-h-0 flex-1', className)} {...props}>
      {/* ... */}
    </div>
  </ChatProvider>
)
```

A pure provider (only other providers, no DOM element) takes `React.PropsWithChildren`, no merge or spread.

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
