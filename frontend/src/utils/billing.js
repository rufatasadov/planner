// Display prices; the amount actually charged comes from the payment provider at checkout.
export const PRICES = {
  pro_monthly: { usd: 4.99, period: 'month' },
  pro_yearly: { usd: 39.99, period: 'year' },
};

export const YEARLY_SAVING_PCT = Math.round((1 - PRICES.pro_yearly.usd / (PRICES.pro_monthly.usd * 12)) * 100);

export const fmtUsd = (n) => `$${n.toFixed(2)}`;

export function trialDaysLeft(billing) {
  if (billing?.source !== 'trial' || !billing.trial_ends_at) return null;
  return Math.max(0, Math.ceil((new Date(billing.trial_ends_at) - Date.now()) / 864e5));
}

export const isPaymentRequired = (e) => e?.response?.status === 402;
