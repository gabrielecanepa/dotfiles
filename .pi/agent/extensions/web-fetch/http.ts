import dns from 'node:dns/promises'
import http, { type IncomingMessage } from 'node:http'
import https from 'node:https'
import { BlockList, isIP } from 'node:net'
import { type Readable } from 'node:stream'

const blockedIPv4 = new BlockList()
for (const [address, prefix] of [
  ['0.0.0.0', 8],
  ['10.0.0.0', 8],
  ['100.64.0.0', 10],
  ['127.0.0.0', 8],
  ['169.254.0.0', 16],
  ['172.16.0.0', 12],
  ['192.0.0.0', 24],
  ['192.0.2.0', 24],
  ['192.88.99.0', 24],
  ['192.168.0.0', 16],
  ['198.18.0.0', 15],
  ['198.51.100.0', 24],
  ['203.0.113.0', 24],
  ['224.0.0.0', 4],
  ['240.0.0.0', 4],
] as const)
  blockedIPv4.addSubnet(address, prefix, 'ipv4')

const publicIPv6 = new BlockList()
publicIPv6.addSubnet('2000::', 3, 'ipv6')
const blockedIPv6 = new BlockList()
for (const [address, prefix] of [
  ['2001::', 23],
  ['2001:db8::', 32],
  ['2002::', 16],
  ['3fff::', 20],
] as const)
  blockedIPv6.addSubnet(address, prefix, 'ipv6')

export const isPublicAddress = (address: string) => {
  const family = isIP(address)
  if (family === 4) return !blockedIPv4.check(address, 'ipv4')
  return family === 6 && publicIPv6.check(address, 'ipv6') && !blockedIPv6.check(address, 'ipv6')
}

export const parsePublicUrl = (input: string) => {
  const url = new URL(input)
  if (url.protocol !== 'http:' && url.protocol !== 'https:')
    throw new Error('Only public HTTP(S) URLs are supported')
  if (url.username || url.password) throw new Error('URLs with credentials are not supported')
  const hostname = url.hostname.replace(/^\[|\]$/g, '')
  if (isIP(hostname) && !isPublicAddress(hostname))
    throw new Error('Private and special-use addresses are not supported; use the browser workflow')
  url.hash = ''
  return url
}

const lookupPublic: NonNullable<http.RequestOptions['lookup']> = (hostname, options, callback) => {
  void (async () => {
    try {
      const records = await dns.lookup(hostname, { all: true, verbatim: true })
      if (!records.length || records.some(record => !isPublicAddress(record.address)))
        throw new Error('The hostname resolves to a private or special-use address')
      const candidates = options.family
        ? records.filter(record => record.family === options.family)
        : records
      if (!candidates.length)
        throw new Error('No public address matches the requested address family')
      if (options.all) {
        callback(null, candidates)
        return
      }
      callback(null, candidates[0].address, candidates[0].family)
    } catch (error) {
      callback(error instanceof Error ? error : new Error('DNS lookup failed'), '')
    }
  })()
}

export const readBody = async (stream: Readable, limit: number, signal?: AbortSignal) => {
  signal?.throwIfAborted()
  const abort = () => stream.destroy(new Error('Fetch cancelled'))
  signal?.addEventListener('abort', abort, { once: true })
  const chunks: Buffer[] = []
  let size = 0
  try {
    for await (const chunk of stream) {
      signal?.throwIfAborted()
      const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)
      size += buffer.length
      if (size > limit) throw new Error('Response too large')
      chunks.push(buffer)
    }
    return Buffer.concat(chunks)
  } finally {
    signal?.removeEventListener('abort', abort)
    stream.destroy()
  }
}

export const fetchPublic = async (input: string, signal: AbortSignal) => {
  let url = parsePublicUrl(input)
  for (let redirects = 0; redirects <= 3; redirects++) {
    signal.throwIfAborted()
    const response = await new Promise<IncomingMessage>((resolve, reject) => {
      const request = (url.protocol === 'https:' ? https : http).get(
        url,
        {
          agent: false,
          lookup: lookupPublic,
          signal,
          headers: {
            'User-Agent': 'Pi web_fetch',
            Accept: 'text/html,application/xhtml+xml,text/plain,application/pdf',
            'Accept-Encoding': 'identity',
          },
        },
        resolve
      )
      request.on('error', reject)
    })
    const status = response.statusCode ?? 0
    if ([301, 302, 303, 307, 308].includes(status)) {
      response.destroy()
      if (!response.headers.location) throw new Error('Redirect has no Location header')
      if (redirects === 3) throw new Error('Too many redirects')
      url = parsePublicUrl(new URL(response.headers.location, url).href)
      continue
    }
    if (status < 200 || status >= 300) {
      response.destroy()
      throw new Error(`HTTP ${status}`)
    }
    const encoding = response.headers['content-encoding']
    if (encoding && encoding !== 'identity') {
      response.destroy()
      throw new Error('Compressed responses are not supported')
    }
    const contentType = (response.headers['content-type'] ?? '').split(';')[0].toLowerCase()
    const pdf = contentType === 'application/pdf' || url.pathname.toLowerCase().endsWith('.pdf')
    const limit = (pdf ? 20 : 5) * 1024 * 1024
    const size = Number(response.headers['content-length'])
    if (Number.isFinite(size) && size > limit) {
      response.destroy()
      throw new Error('Response too large')
    }
    return {
      url: url.href,
      contentType: pdf ? 'application/pdf' : contentType,
      body: await readBody(response, limit, signal),
    }
  }
  throw new Error('Too many redirects')
}
