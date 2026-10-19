import { type ExtensionUIContext } from '@earendil-works/pi-coding-agent'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { resolve } from 'node:path'

export interface TestContext {
  mode?: string
  hasUI?: boolean
  ui?: Partial<ExtensionUIContext>
}

export interface TestToolResult<T extends Record<string, unknown>> {
  isError?: boolean
  content: { type: string; text: string }[]
  details: T
}

export interface TestTool {
  name: string
  exposure?: string
  execute: <T extends Record<string, unknown> = Record<string, unknown>>(
    toolCallId: string,
    params: object,
    signal?: AbortSignal,
    onUpdate?: unknown,
    ctx?: TestContext
  ) => Promise<TestToolResult<T>>
}

interface ExtensionModule {
  default: (pi: object) => void
}

const agentDir = resolve(import.meta.dirname, '..')
const version = (await readFile(resolve(agentDir, 'install/current-version'), 'utf8')).trim()
const runtimeDir = resolve(agentDir, 'install/releases', version, 'node_modules')
const require = createRequire(resolve(runtimeDir, '@earendil-works/pi-coding-agent/package.json'))
const { createJiti } = require('jiti')

const jiti = createJiti(import.meta.url, {
  moduleCache: false,
  alias: Object.fromEntries([
    [
      '@earendil-works/pi-coding-agent',
      resolve(runtimeDir, '@earendil-works/pi-coding-agent/dist/index.js'),
    ],
    ['@earendil-works/pi-tui', require.resolve('@earendil-works/pi-tui')],
    [
      '@mariozechner/pi-coding-agent',
      resolve(runtimeDir, '@earendil-works/pi-coding-agent/dist/index.js'),
    ],
    ['@mariozechner/pi-tui', require.resolve('@earendil-works/pi-tui')],
    ['typebox', require.resolve('typebox')],
    ['@sinclair/typebox', require.resolve('typebox')],
  ]),
})

export const loadExtension = async <TModule extends object = object>(path: string) => {
  const module = (await jiti.import(resolve(import.meta.dirname, path))) as TModule &
    ExtensionModule
  const tools = new Map<string, TestTool>()
  const handlers = new Map<string, (...args: unknown[]) => unknown>()
  module.default({
    registerTool: (tool: TestTool) => tools.set(tool.name, tool),
    on: (event: string, handler: (...args: unknown[]) => unknown) => handlers.set(event, handler),
  })
  assert.equal(tools.size, 1)
  return { module, tool: [...tools.values()][0], handlers }
}
