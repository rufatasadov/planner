import { query } from '../db.js';
import { isAdminEmail } from '../middleware/auth.js';
import { HttpError } from '../utils/http.js';

export const TRIAL_DAYS = 14;

// null = unlimited. Hitting a limit never deletes data: it only blocks creating more / viewing older days.
export const PLAN_LIMITS = {
  free: { projects: 3, history_days: 14 },
  pro: { projects: null, history_days: null },
};

// List prices in USD, used for the admin MRR estimate (the real amounts come from the payment provider).
export const PRODUCTS = {
  pro_monthly: { usd: 4.99, months: 1 },
  pro_yearly: { usd: 39.99, months: 12 },
};

// Subscription statuses that keep Pro (past_due: the provider is still retrying the payment).
const LIVE_STATUSES = ['trialing', 'active', 'past_due'];
// A missed renewal webhook must not downgrade a paying user right away.
const PERIOD_GRACE = "interval '3 days'";

/** SQL condition for a subscription row (alias s) that currently grants Pro. */
export const LIVE_SUBSCRIPTION_SQL = `s.status IN (${LIVE_STATUSES.map((x) => `'${x}'`).join(', ')})
  AND (s.current_period_end IS NULL OR s.current_period_end > now() - ${PERIOD_GRACE})`;

/**
 * { plan: 'free'|'pro', source: 'admin'|'subscription'|'promo'|'trial'|null, trial_ends_at, subscription, limits }
 * A paid subscription wins over a promo one.
 */
export async function getBilling(userId, email) {
  const { rows } = await query(
    `SELECT u.email, u.trial_ends_at,
       (SELECT row_to_json(x) FROM (
          SELECT s.provider, s.product_id, s.status, s.current_period_end, s.will_renew
          FROM subscriptions s
          WHERE s.user_id = u.id AND ${LIVE_SUBSCRIPTION_SQL}
          ORDER BY (s.provider = 'promo'), s.current_period_end DESC NULLS FIRST
          LIMIT 1) x) AS subscription
     FROM users u WHERE u.id = $1`,
    [userId],
  );
  const row = rows[0];
  if (!row) return null;

  let source = null;
  if (isAdminEmail(email ?? row.email)) source = 'admin';
  else if (row.subscription) source = row.subscription.provider === 'promo' ? 'promo' : 'subscription';
  else if (row.trial_ends_at && new Date(row.trial_ends_at) > new Date()) source = 'trial';
  const plan = source ? 'pro' : 'free';

  return {
    plan,
    source,
    trial_ends_at: row.trial_ends_at,
    subscription: row.subscription,
    limits: PLAN_LIMITS[plan],
  };
}

const paymentRequired = (key, params, details) => new HttpError(402, key, params, details);

export async function assertProjectLimit(userId, email) {
  const { limits } = await getBilling(userId, email);
  if (limits.projects === null) return;
  const { rows } = await query('SELECT count(*)::int AS n FROM projects WHERE user_id = $1', [userId]);
  if (rows[0].n >= limits.projects) {
    throw paymentRequired('plan.projectLimit', { max: limits.projects }, { limit: 'projects', max: limits.projects });
  }
}

/** First visible plan date ('YYYY-MM-DD', in the user's time zone) or null when history is unlimited. */
export async function historyStart(userId, email) {
  const { limits } = await getBilling(userId, email);
  if (limits.history_days === null) return null;
  const { rows } = await query(
    `SELECT to_char((now() AT TIME ZONE COALESCE(s.timezone, 'UTC'))::date - ($2::int - 1), 'YYYY-MM-DD') AS d
     FROM users u LEFT JOIN user_settings s ON s.user_id = u.id WHERE u.id = $1`,
    [userId, limits.history_days],
  );
  return rows[0].d;
}
