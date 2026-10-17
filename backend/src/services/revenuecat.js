import { timingSafeEqual } from 'node:crypto';

// RevenueCat sends the Authorization header exactly as configured in the dashboard.
export function webhookAuthorized(header, expected) {
  if (!expected || typeof header !== 'string') return false;
  const a = Buffer.from(header);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

const PROVIDER = {
  APP_STORE: 'app_store',
  MAC_APP_STORE: 'app_store',
  PLAY_STORE: 'play_store',
  TEST_STORE: 'test_store',
  PROMOTIONAL: 'promo',
};

const APPLIED_TYPES = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'CANCELLATION',
  'UNCANCELLATION',
  'NON_RENEWING_PURCHASE',
  'EXPIRATION',
  'BILLING_ISSUE',
  'PRODUCT_CHANGE',
  'SUBSCRIPTION_EXTENDED',
  'TEMPORARY_ENTITLEMENT_GRANT',
  'SUBSCRIPTION_PAUSED',
]);

function userIdOf(value) {
  const n = Number(value);
  return Number.isInteger(n) && n > 0 ? n : null;
}

function productId(raw) {
  const id = String(raw ?? '').toLowerCase();
  if (id.includes('year') || id.includes('annual')) return 'pro_yearly';
  return 'pro_monthly';
}

function statusFor(event) {
  if (event.type === 'EXPIRATION') return 'canceled';
  if (event.type === 'BILLING_ISSUE') return 'past_due';
  if (event.type === 'SUBSCRIPTION_PAUSED') return 'paused';
  if (event.type === 'CANCELLATION' && event.cancel_reason === 'CUSTOMER_SUPPORT') return 'canceled';
  return event.period_type === 'TRIAL' ? 'trialing' : 'active';
}

/** Fields for one subscriptions row, or null when this event should not change one. */
export function mapRevenueCatEvent(event) {
  if (!event || event.type === 'TRANSFER' || !APPLIED_TYPES.has(event.type)) return null;
  const provider = PROVIDER[event.store];
  const userId = userIdOf(event.app_user_id) ?? userIdOf(event.original_app_user_id);
  const externalId = event.original_transaction_id || event.transaction_id;
  if (!provider || !userId || !externalId) return null;

  const status = statusFor(event);
  const willRenew = !['CANCELLATION', 'EXPIRATION', 'SUBSCRIPTION_PAUSED'].includes(event.type) && status !== 'canceled';
  return {
    userId,
    provider,
    externalId: String(externalId),
    productId: productId(event.product_id),
    status,
    periodEnd: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
    willRenew,
    updatedAt: new Date(event.event_timestamp_ms || Date.now()).toISOString(),
  };
}

async function applyTransfer(client, event) {
  const to = (Array.isArray(event.transferred_to) ? event.transferred_to : []).map(userIdOf).find(Boolean);
  const from = (Array.isArray(event.transferred_from) ? event.transferred_from : []).map(userIdOf).filter(Boolean);
  if (!to || !from.length) return;
  const { rows } = await client.query('SELECT id FROM users WHERE id = $1', [to]);
  if (!rows[0]) return;
  const updatedAt = new Date(event.event_timestamp_ms || Date.now()).toISOString();
  await client.query(
    `UPDATE subscriptions SET user_id = $1, provider_updated_at = $3, updated_at = now()
     WHERE user_id = ANY($2::int[]) AND provider IN ('app_store', 'play_store', 'promo')
       AND (provider_updated_at IS NULL OR provider_updated_at <= $3)`,
    [to, from, updatedAt],
  );
}

/** Upserts the store subscription. An older event never overwrites a newer state. */
export async function applyRevenueCatEvent(client, event) {
  if (event?.type === 'TRANSFER') {
    await applyTransfer(client, event);
    return;
  }
  const row = mapRevenueCatEvent(event);
  if (!row) return;
  const { rows } = await client.query('SELECT id FROM users WHERE id = $1', [row.userId]);
  if (!rows[0]) {
    console.warn(`RevenueCat event ${event.id}: no user ${row.userId}`);
    return;
  }
  await client.query(
    `INSERT INTO subscriptions
       (user_id, provider, external_id, product_id, status, current_period_end, will_renew, provider_updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (provider, external_id) DO UPDATE SET
       user_id = EXCLUDED.user_id, product_id = EXCLUDED.product_id, status = EXCLUDED.status,
       current_period_end = EXCLUDED.current_period_end, will_renew = EXCLUDED.will_renew,
       provider_updated_at = EXCLUDED.provider_updated_at, updated_at = now()
     WHERE subscriptions.provider_updated_at IS NULL OR subscriptions.provider_updated_at <= EXCLUDED.provider_updated_at`,
    [row.userId, row.provider, row.externalId, row.productId, row.status, row.periodEnd, row.willRenew, row.updatedAt],
  );
}
