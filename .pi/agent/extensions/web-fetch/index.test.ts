import assert from 'node:assert/strict'
import dns from 'node:dns/promises'
import { EventEmitter } from 'node:events'
import { readFile, rm, stat } from 'node:fs/promises'
import http from 'node:http'
import https from 'node:https'
import { dirname } from 'node:path'
import { Readable } from 'node:stream'
import { mock, test, type TestContext } from 'node:test'
import { loadExtension } from '../utils.mts'

const load = () => loadExtension<typeof import('./index.ts')>('web-fetch/index.ts')

test('rejects private, special-use, mapped and non-HTTP URLs without a fallback', async () => {
  const { tool } = await load()
  let requests = 0
  const fetch = mock.method(globalThis, 'fetch', () => {
    requests++
    return new Response('Unexpected request', { headers: { 'content-type': 'text/plain' } })
  })
  try {
    for (const url of [
      'http://127.0.0.1/',
      'http://10.0.0.1/',
      'http://169.254.169.254/',
      'http://[::1]/',
      'http://[::ffff:127.0.0.1]/',
      'file:///etc/hosts',
      'ftp://example.com/',
      'https://user:pass@example.com/',
    ]) {
      await assert.rejects(tool.execute('fetch-test', { url }))
    }
    assert.equal(requests, 0)
  } finally {
    fetch.mock.restore()
  }
})

test('address classification blocks special-use IPs and permits public addresses', async () => {
  const { module } = await load()
  for (const address of [
    '0.0.0.0',
    '100.64.0.1',
    '192.168.1.1',
    '198.18.0.1',
    '224.0.0.1',
    '::',
    'fc00::1',
    'fe80::1',
    '2001:db8::1',
    '2002:7f00:1::',
  ]) {
    assert.equal(module.isPublicAddress(address), false, address)
  }
  assert.equal(module.isPublicAddress('8.8.8.8'), true)
  assert.equal(module.isPublicAddress('2606:4700:4700::1111'), true)
})

test('enforces streaming byte limits without Content-Length', async () => {
  const { module } = await load()
  const response = Readable.from([Buffer.alloc(6), Buffer.alloc(6)])
  await assert.rejects(module.readBody(response, 10), /too large/)
  assert.equal(response.destroyed, true)
})

test('validates redirects, denies credentials, and strips fragments', async () => {
  const { module } = await load()
  assert.equal(
    module.parsePublicUrl('https://example.com/a#fragment').href,
    'https://example.com/a'
  )
  assert.throws(() => module.parsePublicUrl('http://127.1/'), /public|private/i)
  assert.throws(
    () => module.parsePublicUrl('https://example.com@127.0.0.1/'),
    /credentials|public|private/i
  )
})

test('HTML and plain text extraction are bounded and do not need Jina', async () => {
  const { module } = await load()
  const text = await module.extractContent(
    Buffer.from('Plain text'),
    'text/plain',
    'https://example.com/a'
  )
  assert.equal(text.content, 'Plain text')
  const html =
    '<html><head><title>Test page</title></head><body><article><h1>Heading</h1><p>' +
    'Readable article content. '.repeat(80) +
    '</p></article></body></html>'
  const article = await module.extractContent(
    Buffer.from(html),
    'text/html',
    'https://example.com/a'
  )
  assert.match(article.content, /Readable article content/)
  assert.ok(article.title)
})

test('body reads respect cancellation', async () => {
  const { module } = await load()
  const controller = new AbortController()
  controller.abort()
  await assert.rejects(module.readBody(Readable.from([Buffer.from('body')]), 10, controller.signal))
})

interface Step {
  status?: number
  headers?: Record<string, string>
  body?: string
  chunks?: Buffer[]
}

interface RequestOptions {
  agent?: unknown
  headers: Record<string, string>
  lookup: (hostname: string, options: object, callback: (error: Error | null) => void) => void
}

const network = (
  t: TestContext,
  steps: Step[],
  addresses = [{ address: '8.8.8.8', family: 4 }]
) => {
  const calls: { url: string; options: RequestOptions }[] = []
  t.mock.method(dns, 'lookup', () => addresses)
  const get = (url: URL, options: RequestOptions, onResponse: (response: Readable) => void) => {
    calls.push({ url: url.href, options })
    const request = new EventEmitter()
    queueMicrotask(() =>
      options.lookup(url.hostname, { all: true }, error => {
        if (error) {
          request.emit('error', error)
          return
        }
        const step = steps.shift()
        if (!step) {
          request.emit('error', new Error('Unexpected request'))
          return
        }
        const response = Object.assign(
          Readable.from(step.chunks ?? [Buffer.from(step.body ?? 'Body')]),
          {
            statusCode: step.status ?? 200,
            headers: step.headers ?? { 'content-type': 'text/plain' },
          }
        )
        onResponse(response)
      })
    )
    return request
  }
  t.mock.method(http, 'get', get as unknown as typeof http.get)
  t.mock.method(https, 'get', get as unknown as typeof https.get)
  return calls
}

test('DNS validation pins public results and blocks private or mixed answers', async t => {
  const { module } = await load()
  for (const addresses of [
    [{ address: '127.0.0.1', family: 4 }],
    [
      { address: '8.8.8.8', family: 4 },
      { address: '10.0.0.1', family: 4 },
    ],
  ]) {
    network(t, [], addresses)
    await assert.rejects(
      module.fetchPublic('https://public.example/', AbortSignal.timeout(1000)),
      /private|special-use/
    )
    t.mock.restoreAll()
  }
  const calls = network(t, [{ body: 'Public body' }])
  const result = await module.fetchPublic('https://public.example/', AbortSignal.timeout(1000))
  assert.equal(result.body.toString(), 'Public body')
  assert.equal(calls[0].options.agent, false)
  assert.equal(calls[0].options.headers['Accept-Encoding'], 'identity')
})

test('revalidates redirected URLs and bounds redirects', async t => {
  const { module } = await load()
  const calls = network(t, [{ status: 302, headers: { location: 'http://127.0.0.1/' } }])
  await assert.rejects(
    module.fetchPublic('https://public.example/', AbortSignal.timeout(1000)),
    /Private/
  )
  assert.equal(calls.length, 1)
  t.mock.restoreAll()
  network(
    t,
    Array.from({ length: 4 }, () => ({ status: 302, headers: { location: '/again' } }))
  )
  await assert.rejects(
    module.fetchPublic('https://public.example/', AbortSignal.timeout(1000)),
    /Too many redirects/
  )
})

test('rejects compressed, oversized and failed HTTP responses', async t => {
  const { module } = await load()
  const cases: [Step, RegExp][] = [
    [{ headers: { 'content-encoding': 'gzip' } }, /Compressed/],
    [
      { headers: { 'content-length': String(6 * 1024 * 1024), 'content-type': 'text/plain' } },
      /too large/,
    ],
    [{ status: 403 }, /HTTP 403/],
  ]
  for (const [step, expected] of cases) {
    network(t, [step])
    await assert.rejects(
      module.fetchPublic('https://public.example/', AbortSignal.timeout(1000)),
      expected
    )
    t.mock.restoreAll()
  }
})

test('truncates model output and saves complete content with private permissions', async t => {
  const { tool } = await load()
  const body = 'Line of output\n'.repeat(4000)
  network(t, [{ body }])
  const result = await tool.execute<{ fullOutputPath: string }>('spill-test', {
    url: 'https://public.example/',
  })
  const path = result.details.fullOutputPath
  assert.ok(path)
  try {
    assert.ok(Buffer.byteLength(result.content[0].text) < 51 * 1024)
    assert.match(await readFile(path, 'utf8'), /Line of output/)
    assert.equal((await stat(path)).mode & 0o777, 0o600)
    assert.equal((await stat(dirname(path))).mode & 0o777, 0o700)
  } finally {
    await rm(dirname(path), { recursive: true })
  }
})

test('extracts PDF text and metadata locally', async () => {
  const { module } = await load()
  const content = 'BT /F1 12 Tf 72 720 Td (Hello PDF) Tj ET'
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Length ' + Buffer.byteLength(content) + ' >>\nstream\n' + content + '\nendstream',
    '<< /Title (Synthetic PDF) >>',
  ]
  let pdf = '%PDF-1.4\n'
  const offsets = [0]
  for (const [index, object] of objects.entries()) {
    offsets.push(Buffer.byteLength(pdf))
    pdf += index + 1 + ' 0 obj\n' + object + '\nendobj\n'
  }
  const xref = Buffer.byteLength(pdf)
  pdf += 'xref\n0 7\n0000000000 65535 f \n'
  pdf += offsets
    .slice(1)
    .map(offset => String(offset).padStart(10, '0') + ' 00000 n \n')
    .join('')
  pdf += 'trailer\n<< /Size 7 /Root 1 0 R /Info 6 0 R >>\nstartxref\n' + xref + '\n%%EOF'
  const result = await module.extractContent(
    Buffer.from(pdf),
    'application/pdf',
    'https://public.example/test.pdf'
  )
  assert.match(result.content, /Hello PDF/)
  assert.equal(result.title, 'Synthetic PDF')
})
