import { homedir } from 'node:os'
import { join } from 'node:path'
import { type ExtensionAPI, type ExtensionContext } from '@earendil-works/pi-coding-agent'
import { runHook } from './autoname-session/run-hook.mts'

export default (pi: ExtensionAPI, generate = runHook) => {
  let pending: Promise<void> | undefined
  let controller: AbortController | undefined

  const nameSession = async (prompt: string, ctx: ExtensionContext, signal: AbortSignal) => {
    try {
      const sessionId = ctx.sessionManager.getSessionId()
      const originalName = pi.getSessionName()
      const result = await generate(
        join(homedir(), '.agents/hooks/autoname-session.sh'),
        JSON.stringify({ session_id: `pi-${sessionId}`, prompt: prompt.slice(0, 1000) }),
        ctx.cwd,
        signal
      )
      if (!result.trim() || signal.aborted) return
      const output: unknown = JSON.parse(result)
      if (!output || typeof output !== 'object' || !('hookSpecificOutput' in output)) return
      const hook = output.hookSpecificOutput
      if (!hook || typeof hook !== 'object' || !('sessionTitle' in hook)) return
      const name = hook.sessionTitle
      if (typeof name !== 'string' || !/^[a-z0-9]{1,20}(-[a-z0-9]{1,20}){1,3}$/.test(name)) return
      if (ctx.sessionManager.getSessionId() !== sessionId || pi.getSessionName() !== originalName)
        return
      pi.setSessionName(name)
    } catch (error: unknown) {
      if (!signal.aborted) {
        console.warn(`Pi autoname: ${error instanceof Error ? error.message : 'hook failed'}`)
      }
    }
  }

  pi.on('before_agent_start', (event, ctx) => {
    if (event.messageType !== 'user' || pending || pi.getSessionName()) return
    const prompt = event.prompt.trim()
    if (!prompt || /^[/!#]/.test(prompt)) return
    controller = new AbortController()
    const { signal } = controller
    const run = async () => {
      try {
        await nameSession(prompt, ctx, signal)
      } finally {
        pending = undefined
      }
    }
    pending = run()
  })

  pi.on('session_shutdown', async event => {
    if (event.reason !== 'quit') controller?.abort()
    await pending
  })
}
