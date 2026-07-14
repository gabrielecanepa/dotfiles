import { translate } from './i18n'

type CheckoutStatus = 'idle' | 'processing'

export const checkoutCopy = (locale: 'en' | 'it', status: CheckoutStatus, amount: string) => ({
  pay: translate(locale, 'checkout.pay'),
  status: translate(locale, `status.${status}`),
  title: translate(locale, 'checkout.title'),
  total: translate(locale, 'checkout.total').replace('{amount}', amount),
})
