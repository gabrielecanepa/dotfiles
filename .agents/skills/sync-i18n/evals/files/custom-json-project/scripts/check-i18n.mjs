import { readFile } from 'node:fs/promises'

const localeUrls = [
  new URL('../src/checkout/locales/en.json', import.meta.url),
  new URL('../src/checkout/locales/it.json', import.meta.url),
]
const catalogs = await Promise.all(localeUrls.map(async url => JSON.parse(await readFile(url))))
const flatten = (value, prefix = '') =>
  Object.entries(value).flatMap(([key, child]) => {
    const path = prefix ? `${prefix}.${key}` : key

    return typeof child === 'object' && child !== null ? flatten(child, path) : [[path, child]]
  })
const sourceKeys = flatten(catalogs[0])
  .map(([key]) => key)
  .sort()

for (const catalog of catalogs.slice(1)) {
  const keys = flatten(catalog)
    .map(([key]) => key)
    .sort()

  if (JSON.stringify(keys) !== JSON.stringify(sourceKeys)) {
    throw new Error('Catalog shape mismatch')
  }
}

console.log(`Validated ${sourceKeys.length} custom messages`)
