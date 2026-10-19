import assert from 'node:assert/strict'
import { test } from 'node:test'
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir, homedir } from 'node:os'
import { join } from 'node:path'
import { spawnSync } from 'node:child_process'
import { type ExtensionAPI, type ExtensionContext } from '@earendil-works/pi-coding-agent'
import autoname from '../autoname-session.ts'
import { runHook } from '../autoname-session/run-hook.mts'

const success = (name = 'fix-login-tests') =>
  JSON.stringify({ hookSpecificOutput: { sessionTitle: name } })

const harness = () => {
  const handlers = new Map<
    string,
    (event: Record<string, unknown>, ctx: ExtensionContext) => unknown
  >()
  let name: string | undefined
  let sessionId = 'session-one'
  let resolve!: (value: string) => void
  let reject!: (error: Error) => void
  const calls: unknown[][] = []
  const pi = {
    on: (
      event: string,
      handler: (event: Record<string, unknown>, ctx: ExtensionContext) => unknown
    ) => {
      handlers.set(event, handler)
    },
    getSessionName: () => name,
    setSessionName: (value: string) => {
      name = value
    },
  }
  const ctx = {
    cwd: tmpdir(),
    sessionManager: { getSessionId: () => sessionId },
  } as unknown as ExtensionContext
  const generate = (...args: Parameters<typeof runHook>) => {
    calls.push(args)
    return new Promise<string>((done, fail) => {
      resolve = done
      reject = fail
    })
  }
  autoname(pi as unknown as ExtensionAPI, generate)
  return {
    calls,
    start: (prompt = 'Fix the login tests', messageType = 'user') =>
      handlers.get('before_agent_start')!({ prompt, messageType }, ctx),
    shutdown: (reason = 'quit') => handlers.get('session_shutdown')!({ reason }, ctx),
    finish: async (result = success()) => {
      resolve(result)
      await new Promise(done => setImmediate(done))
    },
    fail: async () => {
      reject(new Error('test failure'))
      await new Promise(done => setImmediate(done))
    },
    getName: () => name,
    setName: pi.setSessionName,
    switchSession: () => {
      sessionId = 'session-two'
    },
  }
}

test('names a session asynchronously using the shared hook with stdin input', async () => {
  const h = harness()
  const prompt = 'Fix "$(touch /tmp/not-executed)" tests\nwith quotes'
  assert.equal(h.start(prompt), undefined)
  assert.equal(h.calls.length, 1)
  const [hook, input, cwd] = h.calls[0] as [string, string, string]
  assert.equal(hook, join(homedir(), '.agents/hooks/autoname-session.sh'))
  assert.deepEqual(JSON.parse(input), { session_id: 'pi-session-one', prompt })
  assert.equal(cwd, tmpdir())
  await h.finish()
  assert.equal(h.getName(), 'fix-login-tests')
  h.start()
  assert.equal(h.calls.length, 1)
})

test('skips custom runs, commands, empty input, and already named sessions', () => {
  const h = harness()
  for (const prompt of ['', '   ', '/name custom', '!pwd', '#remember']) h.start(prompt)
  h.start('Background notification', 'custom')
  h.setName('My deliberate title')
  h.start()
  assert.equal(h.calls.length, 0)
})

test('deduplicates in-flight calls and bounds prompt length', async () => {
  const h = harness()
  h.start('a'.repeat(2000))
  h.start()
  assert.equal(h.calls.length, 1)
  assert.equal(JSON.parse(h.calls[0][1] as string).prompt.length, 1000)
  await h.finish()
})

test('does not overwrite a manual rename made during generation', async () => {
  const h = harness()
  h.start()
  h.setName('Keep this title')
  await h.finish()
  assert.equal(h.getName(), 'Keep this title')
})

test('does not rename a different session', async () => {
  const h = harness()
  h.start()
  h.switchSession()
  await h.finish()
  assert.equal(h.getName(), undefined)
})

for (const reason of ['reload', 'new', 'resume', 'fork']) {
  test(`cancels naming on ${reason}`, async () => {
    const h = harness()
    h.start()
    const shuttingDown = h.shutdown(reason)
    const signal = h.calls[0][3] as AbortSignal
    assert.equal(signal.aborted, true)
    await h.finish()
    await shuttingDown
    assert.equal(h.getName(), undefined)
  })
}

test('quit waits for a pending name so print mode persists it', async () => {
  const h = harness()
  h.start()
  const shuttingDown = h.shutdown()
  const signal = h.calls[0][3] as AbortSignal
  assert.equal(signal.aborted, false)
  await h.finish()
  await shuttingDown
  assert.equal(h.getName(), 'fix-login-tests')
})

test('invalid or failed hook output does not rename and allows a later retry', async () => {
  const h = harness()
  for (const result of ['', 'null', '{}', success('Not a slug')]) {
    h.start()
    await h.finish(result)
    assert.equal(h.getName(), undefined)
  }
  h.start()
  await h.finish()
  assert.equal(h.getName(), 'fix-login-tests')
})

test('shared shell hook opts in only for the Pi adapter and bounds retries', () => {
  const scratch = mkdtempSync(join(tmpdir(), 'pi-autoname-test-'))
  try {
    const log = join(scratch, 'calls')
    writeFileSync(
      join(scratch, 'claude'),
      '#!/bin/sh\ncat >/dev/null\nprintf "call\\n" >> "$AUTONAME_TEST_LOG"\nprintf "%s\\n" "$AUTONAME_TEST_NAME"\n',
      { mode: 0o755 }
    )
    const hook = join(homedir(), '.agents/hooks/autoname-session.sh')
    const run = (
      args: string[],
      payload: Record<string, unknown>,
      generated = 'fix-login-tests'
    ) => {
      const result = spawnSync('sh', [hook, ...args], {
        input: JSON.stringify({ session_id: 'pi-test', prompt: 'Fix the login tests', ...payload }),
        encoding: 'utf8',
        timeout: 5000,
        env: {
          ...process.env,
          PI_CODING_AGENT: 'true',
          TMPDIR: scratch,
          PATH: `${scratch}:/opt/homebrew/bin:${process.env.PATH}`,
          AUTONAME_TEST_LOG: log,
          AUTONAME_TEST_NAME: generated,
        },
      })
      assert.equal(result.error, undefined)
      assert.equal(result.status, 0)
      return result.stdout
    }
    assert.equal(run([], {}), '')
    assert.equal(run(['--pi'], { turn_id: 'codex-turn' }), '')
    assert.equal(run(['--pi'], { session_title: 'existing-name' }), '')
    assert.equal(run(['--pi'], { prompt: '/name test' }), '')
    assert.equal(JSON.parse(run(['--pi'], {})).hookSpecificOutput.sessionTitle, 'fix-login-tests')
    for (let attempt = 0; attempt < 7; attempt++) {
      assert.equal(run(['--pi'], { session_id: 'pi-failed' }, 'invalid'), '')
    }
    assert.equal(readFileSync(log, 'utf8').trim().split('\n').length, 6)
  } finally {
    rmSync(scratch, { recursive: true, force: true })
  }
})

test('hook rejection during shutdown is handled without changing the name', async () => {
  const h = harness()
  h.start()
  const shuttingDown = h.shutdown('reload')
  await h.fail()
  await shuttingDown
  assert.equal(h.getName(), undefined)
})

test('runner sends input on stdin, handles failure, and cancels the process group', async () => {
  const scratch = mkdtempSync(join(tmpdir(), 'pi-autoname-runner-'))
  try {
    const script = join(scratch, 'hook.sh')
    const input = JSON.stringify({ prompt: 'literal "$(whoami)" data' })
    writeFileSync(script, '#!/bin/sh\ncat > input.json\nprintf "fix-login-tests"\n')
    assert.equal(
      await runHook(script, input, scratch, new AbortController().signal),
      'fix-login-tests'
    )
    assert.equal(readFileSync(join(scratch, 'input.json'), 'utf8'), input)
    writeFileSync(script, '#!/bin/sh\nexit 1\n')
    assert.equal(await runHook(script, input, scratch, new AbortController().signal), '')
    assert.equal(await runHook(script, input, scratch, AbortSignal.abort()), '')
    writeFileSync(script, '#!/bin/sh\ncat >/dev/null\nsleep 30 &\nwait\n')
    assert.equal(await runHook(script, input, scratch, AbortSignal.timeout(50)), '')
  } finally {
    rmSync(scratch, { recursive: true, force: true })
  }
})
