import { randomUUID } from 'node:crypto';
import { afterAll, describe, expect, test } from 'vitest';
import { pool, query } from '../src/db.js';
import { api, registerUser } from './helpers.js';

afterAll(() => pool.end());

const AUTH = process.env.REVENUECAT_WEBHOOK_AUTH;
const me = async (u) => (await api().get('/api/v1/auth/me').set(u.auth).expect(200)).body.billing;
const endTrial = (u) => query(`UPDATE users SET trial_ends_at = now() - interval '1 day' WHERE id = $1`, [u.user.id]);

function event(u, over = {}) {
  const now = Date.now();
  return {
    api_version: '1.0',
    event: {
      id: randomUUID(),
      type: 'INITIAL_PURCHASE',
      app_user_id: String(u.user.id),
      product_id: 'pro_yearly',
      period_type: 'NORMAL',
      store: 'APP_STORE',
      transaction_id: `txn_${randomUUID()}`,
      original_transaction_id: `orig_${u.user.id}`,
      expiration_at_ms: now + 365 * 864e5,
      event_timestamp_ms: now,
      ...over,
    },
  };
}

function send(body, { authorization = AUTH } = {}) {
  return api()
    .post('/api/v1/billing/webhooks/revenuecat')
    .set('Content-Type', 'application/json')
    .set('Authorization', authorization)
    .send(JSON.stringify(body));
}

describe('revenuecat webhook', () => {
  test('rejects a missing or wrong authorization header', async () => {
    const u = await registerUser();
    const body = event(u);
    await send(body, { authorization: '' }).expect(401);
    await send(body, { authorization: 'Bearer wrong' }).expect(401);
    const { rowCount } = await query('SELECT 1 FROM billing_events WHERE id = $1', [body.event.id]);
    expect(rowCount).toBe(0);
  });

  test('an App Store purchase makes the user Pro and a replay is stored once', async () => {
    const u = await registerUser();
    await endTrial(u);
    const body = event(u);
    await send(body).expect(200);
    expect(await me(u)).toMatchObject({
      plan: 'pro',
      source: 'subscription',
      subscription: { provider: 'app_store', product_id: 'pro_yearly', status: 'active', will_renew: true },
    });

    const again = await send(body).expect(200);
    expect(again.body.duplicate).toBe(true);
    const { rows } = await query('SELECT count(*)::int AS n FROM billing_events WHERE id = $1', [body.event.id]);
    expect(rows[0].n).toBe(1);
  });

  test('Play Store monthly is stored separately and an older event does not win', async () => {
    const u = await registerUser();
    await endTrial(u);
    const now = Date.now();
    const original = `play_${u.user.id}`;
    await send(
      event(u, {
        store: 'PLAY_STORE',
        product_id: 'pro_monthly',
        original_transaction_id: original,
        event_timestamp_ms: now,
        expiration_at_ms: now + 30 * 864e5,
      }),
    ).expect(200);
    expect((await me(u)).subscription).toMatchObject({ provider: 'play_store', product_id: 'pro_monthly' });

    await send(
      event(u, {
        type: 'EXPIRATION',
        store: 'PLAY_STORE',
        product_id: 'pro_monthly',
        original_transaction_id: original,
        event_timestamp_ms: now - 60_000,
        expiration_at_ms: now - 1000,
      }),
    ).expect(200);
    expect((await me(u)).plan).toBe('pro');
  });

  test('cancellation keeps access until the period ends, expiration removes it', async () => {
    const u = await registerUser();
    await endTrial(u);
    const original = `orig_${randomUUID()}`;
    const now = Date.now();
    await send(event(u, { original_transaction_id: original, event_timestamp_ms: now })).expect(200);
    await send(
      event(u, {
        type: 'CANCELLATION',
        original_transaction_id: original,
        event_timestamp_ms: now + 1000,
        expiration_at_ms: now + 10 * 864e5,
      }),
    ).expect(200);
    expect((await me(u)).subscription).toMatchObject({ status: 'active', will_renew: false });

    await send(
      event(u, {
        type: 'EXPIRATION',
        original_transaction_id: original,
        event_timestamp_ms: now + 2000,
        expiration_at_ms: now - 1000,
      }),
    ).expect(200);
    expect(await me(u)).toMatchObject({ plan: 'free', source: null });
  });

  test('a transfer moves the store subscription to the new account', async () => {
    const from = await registerUser();
    const to = await registerUser();
    await endTrial(from);
    await endTrial(to);
    const now = Date.now();
    await send(event(from, { event_timestamp_ms: now })).expect(200);
    await send({
      event: {
        id: randomUUID(),
        type: 'TRANSFER',
        transferred_from: [String(from.user.id)],
        transferred_to: [String(to.user.id)],
        store: 'APP_STORE',
        event_timestamp_ms: now + 1000,
      },
    }).expect(200);
    expect((await me(from)).plan).toBe('free');
    expect((await me(to)).subscription.provider).toBe('app_store');
  });

  test('a Paddle store value is logged and does not create a subscription', async () => {
    const u = await registerUser();
    await endTrial(u);
    const body = event(u, { store: 'PADDLE' });
    await send(body).expect(200);
    const { rowCount } = await query(
      `SELECT 1 FROM subscriptions WHERE user_id = $1 AND provider <> 'paddle'`,
      [u.user.id],
    );
    expect(rowCount).toBe(0);
    expect((await me(u)).plan).toBe('free');
  });
});
