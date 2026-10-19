import { type ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { stripVTControlCharacters } from 'node:util'
import { Type } from 'typebox'

interface Answer {
  type: 'text' | 'option' | 'other'
  label: string
  value: string
  index?: number
}

interface Waiter {
  resolve: (release?: () => void) => void
  signal: AbortSignal
  abort: () => void
}

const clean = (value: string) =>
  [...stripVTControlCharacters(value)]
    .filter(char => {
      const code = char.codePointAt(0) ?? 0
      return code === 0x09 || code === 0x0a || (code > 0x1f && code !== 0x7f)
    })
    .join('')
    .trim()

export default (pi: ExtensionAPI) => {
  let shutdown = new AbortController()
  let active = false
  const waiting: Waiter[] = []

  const release = () => {
    let waiter: Waiter | undefined
    while ((waiter = waiting.shift())) {
      waiter.signal.removeEventListener('abort', waiter.abort)
      if (waiter.signal.aborted) {
        waiter.resolve()
        continue
      }
      waiter.resolve(release)
      return
    }
    active = false
  }

  const acquire = (signal: AbortSignal): Promise<(() => void) | undefined> => {
    if (signal.aborted) return new Promise(resolve => resolve(undefined))
    if (!active) {
      active = true
      return new Promise(resolve => resolve(release))
    }
    return new Promise(resolve => {
      const waiter: Waiter = {
        resolve,
        signal,
        abort: () => {
          const index = waiting.indexOf(waiter)
          if (index !== -1) waiting.splice(index, 1)
          signal.removeEventListener('abort', waiter.abort)
          resolve(undefined)
        },
      }
      waiting.push(waiter)
      signal.addEventListener('abort', waiter.abort, { once: true })
      if (signal.aborted) waiter.abort()
    })
  }

  pi.on('session_start', () => {
    shutdown.abort()
    shutdown = new AbortController()
  })
  pi.on('session_shutdown', () => shutdown.abort())

  pi.registerTool({
    name: 'ask_user_question',
    label: 'Ask User',
    exposure: 'model-only',
    description:
      'Ask one material question through native terminal dialogs. Supports choices, multiple selections, Other, and free text. Never request passwords, tokens, or other secrets.',
    promptSnippet:
      'Ask a concrete question when missing information changes the decision. Put the recommended choice first; Other is added automatically.',
    parameters: Type.Object({
      question: Type.String({ minLength: 1, maxLength: 2000 }),
      details: Type.Optional(Type.String({ maxLength: 4000 })),
      options: Type.Optional(
        Type.Array(
          Type.Object({
            label: Type.String({ minLength: 1, maxLength: 256 }),
            value: Type.Optional(Type.String({ maxLength: 256 })),
            description: Type.Optional(Type.String({ maxLength: 1000 })),
          }),
          { maxItems: 20 }
        )
      ),
      multiSelect: Type.Optional(Type.Boolean()),
    }),
    async execute(_id, params, signal, _update, ctx) {
      const question = clean(params.question)
      if (!question) throw new Error('The question cannot be empty')
      const options = (params.options ?? []).map(option => ({
        label: clean(option.label),
        value: clean(option.value ?? option.label),
        description: option.description ? clean(option.description) : '',
      }))
      if (options.some(option => !option.label)) throw new Error('Choice labels cannot be empty')
      const mode = options.length ? (params.multiSelect ? 'multi-select' : 'single-select') : 'text'
      const operation = signal ? AbortSignal.any([signal, shutdown.signal]) : shutdown.signal
      const result = (
        status: 'answered' | 'cancelled' | 'unavailable',
        answers: Answer[] = []
      ) => ({
        content: [
          {
            type: 'text' as const,
            text:
              status === 'answered'
                ? JSON.stringify({ question, answers })
                : status === 'cancelled'
                  ? 'User cancelled the question. Do not infer an answer.'
                  : 'Question UI requires an interactive Pi terminal session.',
          },
        ],
        details: { status, question, mode, answers },
        ...(status === 'unavailable' ? { isError: true } : {}),
      })
      if (operation.aborted) return result('cancelled')
      if (!ctx.hasUI || ctx.mode !== 'tui') return result('unavailable')
      const unlock = await acquire(operation)
      if (!unlock) return result('cancelled')
      try {
        if (operation.aborted) return result('cancelled')
        const title = params.details ? question + '\n' + clean(params.details) : question
        if (!options.length) {
          const answer = await ctx.ui.input(title, undefined, { signal: operation })
          if (answer === undefined || operation.aborted) return result('cancelled')
          const text = clean(answer).slice(0, 16000)
          return result('answered', [{ type: 'text', label: text, value: text }])
        }
        const selected = new Map<number, Answer>()
        while (!operation.aborted) {
          const labels = options.map(
            (option, index) =>
              (params.multiSelect ? (selected.has(index) ? '[x] ' : '[ ] ') : '') +
              `${index + 1}. ${option.label}` +
              (option.description ? ' - ' + option.description : '')
          )
          const other = selected.has(-1) ? 'Other (remove custom answer)' : 'Other (custom answer)'
          const choices = [...labels, other]
          if (params.multiSelect && selected.size)
            choices.push(`Submit (${selected.size} selected)`)
          const choice = await ctx.ui.select(title, choices, { signal: operation })
          if (choice === undefined || operation.aborted) return result('cancelled')
          if (choice.startsWith('Submit ('))
            return result(
              'answered',
              [...selected.entries()]
                .sort(([a], [b]) => (a < 0 ? 21 : a) - (b < 0 ? 21 : b))
                .map(([, answer]) => answer)
            )
          let index = labels.indexOf(choice)
          let answer: Answer
          if (choice === other) {
            index = -1
            if (selected.has(index)) {
              selected.delete(index)
              continue
            }
            const value = await ctx.ui.input(question + '\nOther', undefined, { signal: operation })
            if (value === undefined || operation.aborted) return result('cancelled')
            const text = clean(value).slice(0, 16000)
            if (!text) continue
            answer = { type: 'other', label: text, value: text }
          } else {
            if (index < 0) throw new Error('The dialog returned an unknown choice')
            answer = {
              type: 'option',
              label: options[index].label,
              value: options[index].value,
              index: index + 1,
            }
          }
          if (!params.multiSelect) return result('answered', [answer])
          if (selected.has(index)) selected.delete(index)
          else selected.set(index, answer)
        }
        return result('cancelled')
      } finally {
        unlock()
      }
    },
  })
}
