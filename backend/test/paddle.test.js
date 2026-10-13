import { randomUUID } from 'node:crypto';
import { afterAll, describe, expect, test } from 'vitest';
import { pool, query } from '../src/db.js';
import { signWebhook, verifyWebhookSignature } from '../src/services/paddle.js';
import { api, registerUser } from './helpers.js';

afterAll(() => pool.end());

const SECRET = process.env.PADDLE_WEBHOOK_SECRET;
const me = async (u) => (await api().get('/api/v1/auth/me').set(u.auth).expect(200)).body.billing;
const endTrial = (u) => query(`UPDATE users SET trial_ends_at = now() - interval '1 day' WHERE id = $1`, [u.user.id]);
const inDays = (n) => new Date(Date.now() + n * 864e5).toISOString();

function subscriptionEvent(u, { type = 'subscription.created', subId = `sub_${randomUUID()}`, ...over } = {}) {
  return {
    event_id: `evt_${randomUUID()}`,
    event_type: type,
    occurred_at: new Date().toISOString(),
    data: {
      id: subId,
      status: 'active',
      customer_id: `ctm_${u.user.id}`,
      custom_data: { user_id: String(u.user.id) },
      items: [{ price: { id: 'pri_test_yearly', billing_cycle: { interval: 'year', frequency: 1 } } }],
      current_billing_period: { starts_at: new Date().toISOString(), ends_at: inDays(365) },
      scheduled_change: null,
      updated_at: new Date().toISOString(),
      ...over,
    },
  };
}

function send(event, { secret = SECRET, signature } = {}) {
  const raw = JSON.stringify(event);
  return api()
    .post('/api/v1/billing/webhooks/paddle')
    .set('Content-Type', 'application/json')
    .set('Paddle-Signature', signature ?? signWebhook(raw, secret))
    .send(raw);
}

describe('webhook signature', () => {
  test('accepts a valid signature and rejects tampering, wrong secret or an old timestamp', () => {
    const body = '{"a":1}';
    const now = 1_800_000_000;
    expect(verifyWebhookSignature(body, signWebhook(body, 's', now), 's', now)).toBe(true);
    expect(verifyWebhookSignature('{"a":2}', signWebhook(body, 's', now), 's', now)).toBe(false);
    expect(verifyWebhookSignature(body, signWebhook(body, 'other', now), 's', now)).toBe(false);
    expect(verifyWebhookSignature(body, signWebhook(body, 's', now - 3600), 's', now)).toBe(false);
    expect(verifyWebhookSignature(body, 'garbage', 's', now)).toBe(false);
  });

  test('unsigned or badly signed webhooks are rejected without side effects', async () => {
    const u = await registerUser();
    const event = subscriptionEvent(u);
    await send(event, { signature: '' }).expect(401);
    await send(event, { secret: 'wrong' }).expect(401);
    const { rowCount } = await query('SELECT 1 FROM billing_events WHERE id = $1', [event.event_id]);
    expect(rowCount).toBe(0);
  });
});

describe('subscription webhooks', () => {
  test('subscription.created makes the user Pro and links the Paddle customer', async () => {
    const u = await registerUser();
    await endTrial(u);
    await send(subscriptionEvent(u)).expect(200);

    expect(await me(u)).toMatchObject({
      plan: 'pro',
      source: 'subscription',
      subscription: { provider: 'paddle', product_id: 'pro_yearly', status: 'active', will_renew: true },
    });
    const { rows } = await query('SELECT paddle_customer_id FROM users WHERE id = $1', [u.user.id]);
    expect(rows[0].paddle_customer_id).toBe(`ctm_${u.user.id}`);
  });

  test('a redelivered event is stored once', async () => {
    const u = await registerUser();
    const event = subscriptionEvent(u);
    await send(event).expect(200);
    const again = await send(event).expect(200);
    expect(again.body.duplicate).toBe(true);
  });

  test('scheduled cancel keeps Pro until the period ends; canceled removes it', async () => {
    const u = await registerUser();
    await endTrial(u);
    const subId = `sub_${randomUUID()}`;
    await send(subscriptionEvent(u, { subId })).expect(200);

    await send(
      subscriptionEvent(u, {
        type: 'subscription.updated',
        subId,
        scheduled_change: { action: 'cancel', effective_at: inDays(365) },
        updated_at: inDays(0.001),
      }),
    ).expect(200);
    expect(await me(u)).toMatchObject({ plan: 'pro', subscription: { will_renew: false } });

    await send(
      subscriptionEvent(u, {
        type: 'subscription.canceled',
        subId,
        status: 'canceled',
        current_billing_period: null,
        updated_at: inDays(0.002),
      }),
    ).expect(200);
    expect(await me(u)).toMatchObject({ plan: 'free', subscription: null });
  });

  test('an older event arriving late does not overwrite a newer state', async () => {
    const u = await registerUser();
    await endTrial(u);
    const subId = `sub_${randomUUID()}`;
    await send(subscriptionEvent(u, { subId, status: 'canceled', current_billing_period: null, updated_at: inDays(0.01) })).expect(200);
    await send(subscriptionEvent(u, { subId, status: 'active', updated_at: inDays(0) })).expect(200);
    expect((await me(u)).plan).toBe('free');
  });

  test('without custom_data the user is found by the linked Paddle customer', async () => {
    const u = await registerUser();
    await endTrial(u);
    await query('UPDATE users SET paddle_customer_id = $2 WHERE id = $1', [u.user.id, `ctm_linked_${u.user.id}`]);
    await send(subscriptionEvent(u, { custom_data: null, customer_id: `ctm_linked_${u.user.id}` })).expect(200);
    expect(await me(u)).toMatchObject({ plan: 'pro', source: 'subscription' });
  });
});

describe('checkout endpoints', () => {
  test('report Paddle as unavailable when it is not configured', async () => {
    const u = await registerUser();
    expect((await api().get('/api/v1/billing/config').set(u.auth).expect(200)).body).toEqual({ provider: null });
    const res = await api().post('/api/v1/billing/checkout').set(u.auth).send({ product: 'pro_yearly' }).expect(503);
    expect(res.body.code).toBe('billing.unavailable');
  });

  test('require auth', async () => {
    await api().post('/api/v1/billing/checkout').send({ product: 'pro_yearly' }).expect(401);
  });
});
