import { spawn } from 'node:child_process'

export const runHook = (hook: string, input: string, cwd: string, signal: AbortSignal) =>
  new Promise<string>((resolve, reject) => {
    if (signal.aborted) {
      resolve('')
      return
    }
    const child = spawn('sh', [hook, '--pi'], {
      cwd,
      detached: true,
      stdio: ['pipe', 'pipe', 'ignore'],
    })
    let output = ''
    let stopped = false
    let forceKill: ReturnType<typeof setTimeout> | undefined
    const kill = (kind: NodeJS.Signals) => {
      if (!child.pid) return
      try {
        process.kill(-child.pid, kind)
      } catch (error: unknown) {
        if (!(error instanceof Error && 'code' in error && error.code === 'ESRCH')) reject(error)
      }
    }
    const stop = () => {
      if (stopped) return
      stopped = true
      kill('SIGTERM')
      forceKill = setTimeout(() => kill('SIGKILL'), 1000)
      forceKill.unref()
    }
    const timeout = setTimeout(stop, 20_000)
    signal.addEventListener('abort', stop, { once: true })
    child.stdout.setEncoding('utf8')
    child.stdout.on('data', (data: string) => {
      output += data
      if (output.length > 4096) stop()
    })
    child.stdin.on('error', () => stop())
    child.on('error', reject)
    child.on('close', code => {
      if (stopped) kill('SIGKILL')
      clearTimeout(timeout)
      if (forceKill) clearTimeout(forceKill)
      signal.removeEventListener('abort', stop)
      resolve(code === 0 && !stopped ? output : '')
    })
    child.stdin.end(input)
    if (signal.aborted) stop()
  })
