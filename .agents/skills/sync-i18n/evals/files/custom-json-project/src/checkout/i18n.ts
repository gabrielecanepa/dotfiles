import en from './locales/en.json'
import it from './locales/it.json'

const catalogs = { en, it }

const lookup = (value: object, key: string) =>
  key
    .split('.')
    .reduce<unknown>(
      (current, segment) =>
        typeof current === 'object' && current !== null ? (current as Record<string, unknown>)[segment] : undefined,
      value
    )

export const translate = (locale: keyof typeof catalogs, key: string) => {
  const message = lookup(catalogs[locale], key)

  if (typeof message !== 'string') {
    throw new Error(`Missing message: ${locale}.${key}`)
  }

  return message
}
