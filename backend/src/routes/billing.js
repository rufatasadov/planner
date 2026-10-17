import { Router } from 'express';
import { query, withTransaction } from '../db.js';
import { HttpError, conflict, notFound, requireOneOf } from '../utils/http.js';
import { LIVE_SUBSCRIPTION_SQL } from '../services/billing.js';
import { paddleApi, paddleConfig, paddleEnabled, verifyWebhookSignature } from '../services/paddle.js';
import { applyRevenueCatEvent, webhookAuthorized } from '../services/revenuecat.js';
import { reportError } from '../sentry.js';

const router = Router();

const unavailable = () => new HttpError(503, 'billing.unavailable');

/** Public: the /checkout page opened from Paddle emails (_ptxn links) may not be logged in. */
export function billingConfig(_req, res) {
  const c = paddleConfig();
  res.json(paddleEnabled() ? { provider: 'paddle', environment: c.env, client_token: c.clientToken } : { provider: null });
}

/** Links the user to a Paddle customer: reuses the stored id, an existing customer with the same email, or creates one. */
async function ensureCustomer(userId) {
  const { rows } = await query('SELECT email, name, paddle_customer_id FROM users WHERE id = $1', [userId]);
  const user = rows[0];
  if (user.paddle_customer_id) return user.paddle_customer_id;

  const found = await paddleApi(`/customers?email=${encodeURIComponent(user.email)}`);
  const customer = found[0] ?? (await paddleApi('/customers', { method: 'POST', body: { email: user.email, name: user.name } }));
  await query('UPDATE users SET paddle_customer_id = $2 WHERE id = $1', [userId, customer.id]);
  return customer.id;
}

const livePaddleSubscriptions = async (userId) =>
  (
    await query(
      `SELECT s.external_id FROM subscriptions s WHERE s.user_id = $1 AND s.provider = 'paddle' AND ${LIVE_SUBSCRIPTION_SQL}`,
      [userId],
    )
  ).rows.map((r) => r.external_id);

// Creates a Paddle transaction for the chosen plan; the web app opens it with Paddle.Checkout.open({ transactionId }).
// custom_data.user_id is set here (not by the browser), and Paddle copies it onto the resulting subscription.
router.post('/checkout', async (req, res) => {
  if (!paddleEnabled()) throw unavailable();
  const product = requireOneOf(req.body.product, 'product', ['pro_monthly', 'pro_yearly']);
  if ((await livePaddleSubscriptions(req.userId)).length) throw conflict('billing.alreadySubscribed');

  const c = paddleConfig();
  const customerId = await ensureCustomer(req.userId);
  const txn = await paddleApi('/transactions', {
    method: 'POST',
    body: {
      items: [{ price_id: c.prices[product], quantity: 1 }],
      customer_id: customerId,
      custom_data: { user_id: String(req.userId) },
    },
  });
  res.json({ transaction_id: txn.id, environment: c.env, client_token: c.clientToken });
});

/** One-time link to Paddle's customer portal (cancel, change card, invoices). */
router.post('/portal', async (req, res) => {
  if (!paddleEnabled()) throw unavailable();
  const { rows } = await query('SELECT paddle_customer_id FROM users WHERE id = $1', [req.userId]);
  const customerId = rows[0]?.paddle_customer_id;
  if (!customerId) throw notFound('billing.noSubscription');
  const session = await paddleApi(`/customers/${customerId}/portal-sessions`, {
    method: 'POST',
    body: { subscription_ids: await livePaddleSubscriptions(req.userId) },
  });
  res.json({ url: session.urls.general.overview });
});

export default router;

// ---------------------------------------------------------------- webhooks

function productForPrice(price) {
  const { prices } = paddleConfig();
  const byId = Object.entries(prices).find(([, id]) => id && id === price?.id);
  if (byId) return byId[0];
  return price?.billing_cycle?.interval === 'year' ? 'pro_yearly' : 'pro_monthly';
}

async function findUserId(client, sub) {
  const fromCustomData = Number(sub.custom_data?.user_id);
  if (Number.isInteger(fromCustomData) && fromCustomData > 0) {
    const { rows } = await client.query('SELECT id FROM users WHERE id = $1', [fromCustomData]);
    if (rows[0]) return rows[0].id;
  }
  const { rows } = await client.query('SELECT id FROM users WHERE paddle_customer_id = $1', [sub.customer_id]);
  return rows[0]?.id ?? null;
}

/** Upserts our copy of a Paddle subscription; an older event never overwrites a newer state. */
export async function applyPaddleSubscription(client, sub) {
  const userId = await findUserId(client, sub);
  if (!userId) {
    console.warn(`Paddle subscription ${sub.id}: no matching user (customer ${sub.customer_id})`);
    return null;
  }
  const status = sub.status;
  const willRenew = ['active', 'trialing', 'past_due'].includes(status) && sub.scheduled_change?.action !== 'cancel';

  await client.query(
    `INSERT INTO subscriptions
       (user_id, provider, external_id, customer_id, product_id, status, current_period_end, will_renew, provider_updated_at)
     VALUES ($1, 'paddle', $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (provider, external_id) DO UPDATE SET
       user_id = EXCLUDED.user_id, customer_id = EXCLUDED.customer_id, product_id = EXCLUDED.product_id,
       status = EXCLUDED.status, current_period_end = EXCLUDED.current_period_end, will_renew = EXCLUDED.will_renew,
       provider_updated_at = EXCLUDED.provider_updated_at, updated_at = now()
     WHERE subscriptions.provider_updated_at IS NULL OR subscriptions.provider_updated_at <= EXCLUDED.provider_updated_at`,
    [
      userId,
      sub.id,
      sub.customer_id,
      productForPrice(sub.items?.[0]?.price),
      status,
      sub.current_billing_period?.ends_at ?? null,
      willRenew,
      sub.updated_at ?? new Date().toISOString(),
    ],
  );
  await client.query('UPDATE users SET paddle_customer_id = $2 WHERE id = $1 AND paddle_customer_id IS NULL', [
    userId,
    sub.customer_id,
  ]);
  return userId;
}

// Mounted before express.json(): the signature is computed over the raw body.
export const webhookRouter = Router();

webhookRouter.post('/paddle', async (req, res) => {
  const { webhookSecret } = paddleConfig();
  if (!webhookSecret) return res.status(503).end();
  const raw = Buffer.isBuffer(req.body) ? req.body.toString('utf8') : '';
  if (!verifyWebhookSignature(raw, req.headers['paddle-signature'], webhookSecret)) return res.status(401).end();

  let event;
  try {
    event = JSON.parse(raw);
  } catch {
    return res.status(400).end();
  }
  if (!event?.event_id || !event.event_type) return res.status(400).end();

  try {
    // Event log and state change commit together; on failure Paddle retries the whole event.
    const duplicate = await withTransaction(async (client) => {
      const ins = await client.query(
        `INSERT INTO billing_events (id, provider, type, payload) VALUES ($1, 'paddle', $2, $3)
         ON CONFLICT (id) DO NOTHING RETURNING id`,
        [event.event_id, event.event_type, event],
      );
      if (!ins.rowCount) return true;
      if (event.event_type.startsWith('subscription.')) await applyPaddleSubscription(client, event.data);
      return false;
    });
    res.json({ ok: true, duplicate });
  } catch (err) {
    console.error(err);
    reportError(err, req);
    res.status(500).end();
  }
});

// RevenueCat dashboard → Integrations → Webhooks.
// Authorization header must equal REVENUECAT_WEBHOOK_AUTH (for example "Bearer <random>").
webhookRouter.post('/revenuecat', async (req, res) => {
  const secret = process.env.REVENUECAT_WEBHOOK_AUTH || '';
  if (!secret) return res.status(503).end();
  if (!webhookAuthorized(req.headers.authorization, secret)) return res.status(401).end();

  const raw = Buffer.isBuffer(req.body) ? req.body.toString('utf8') : '';
  let body;
  try {
    body = JSON.parse(raw);
  } catch {
    return res.status(400).end();
  }
  const event = body?.event;
  if (!event?.id || !event.type) return res.status(400).end();

  try {
    const duplicate = await withTransaction(async (client) => {
      const ins = await client.query(
        `INSERT INTO billing_events (id, provider, type, payload) VALUES ($1, 'revenuecat', $2, $3)
         ON CONFLICT (id) DO NOTHING RETURNING id`,
        [event.id, event.type, body],
      );
      if (!ins.rowCount) return true;
      await applyRevenueCatEvent(client, event);
      return false;
    });
    res.json({ ok: true, duplicate });
  } catch (err) {
    console.error(err);
    reportError(err, req);
    res.status(500).end();
  }
});
