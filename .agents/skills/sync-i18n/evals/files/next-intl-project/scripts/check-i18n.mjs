import { readFile } from 'node:fs/promises'

const locales = ['en', 'it']

const flatten = (value, prefix = '') =>
  Object.entries(value).flatMap(([key, child]) => {
    const path = prefix ? `${prefix}.${key}` : key

    return typeof child === 'object' && child !== null ? flatten(child, path) : [[path, child]]
  })

const catalogs = await Promise.all(
  locales.map(async locale => JSON.parse(await readFile(new URL(`../messages/${locale}.json`, import.meta.url))))
)
const sourceKeys = flatten(catalogs[0])
  .map(([key]) => key)
  .sort()

for (const [index, catalog] of catalogs.entries()) {
  const keys = flatten(catalog)
    .map(([key]) => key)
    .sort()

  if (JSON.stringify(keys) !== JSON.stringify(sourceKeys)) {
    throw new Error(`Catalog shape mismatch for ${locales[index]}`)
  }
}

console.log(`Validated ${sourceKeys.length} messages across ${locales.length} locales`)
