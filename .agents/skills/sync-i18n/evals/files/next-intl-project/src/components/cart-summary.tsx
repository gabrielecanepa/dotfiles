'use client'

import { useTranslations } from 'next-intl'

type PaymentStatus = 'paid' | 'pending'

export const CartSummary = ({ count, status }: { count: number; status: PaymentStatus }) => {
  const actions = useTranslations('Actions')
  const cart = useTranslations('Cart')
  const statuses = useTranslations('Status')

  return (
    <section>
      <p>{cart('items', { count })}</p>
      <p>{statuses(status)}</p>
      <button>{actions('save')}</button>
      <button>{actions('cancel')}</button>
    </section>
  )
}
