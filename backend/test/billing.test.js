import { afterAll, describe, expect, test } from 'vitest';
import { pool, query } from '../src/db.js';
import { adminUser, api, registerUser } from './helpers.js';

afterAll(() => pool.end());

const me = async (u) => (await api().get('/api/v1/auth/me').set(u.auth).expect(200)).body.billing;
const endTrial = (u) => query(`UPDATE users SET trial_ends_at = now() - interval '1 day' WHERE id = $1`, [u.user.id]);
const createProject = (u, name = 'P') => api().post('/api/v1/projects').set(u.auth).send({ name });
const daysAgo = (n) => new Date(Date.now() - n * 864e5).toISOString().slice(0, 10);

async function addSubscription(u, { status = 'active', periodEnd = "now() + interval '30 days'", provider = 'paddle' } = {}) {
  await query(
    `INSERT INTO subscriptions (user_id, provider, external_id, product_id, status, current_period_end)
     VALUES ($1, $2, $3, 'pro_monthly', $4, ${periodEnd})`,
    [u.user.id, provider, `sub-${u.user.id}-${Math.random()}`, status],
  );
}

describe('plan resolution', () => {
  test('a new account starts a 14-day Pro trial', async () => {
    const u = await registerUser();
    expect(u.user.billing).toMatchObject({ plan: 'pro', source: 'trial', limits: { projects: null } });
    const days = (new Date(u.user.billing.trial_ends_at) - Date.now()) / 864e5;
    expect(days).toBeGreaterThan(13.9);
    expect(days).toBeLessThanOrEqual(14);
  });

  test('after the trial the account is Free', async () => {
    const u = await registerUser();
    await endTrial(u);
    expect(await me(u)).toMatchObject({ plan: 'free', source: null, limits: { projects: 3, history_days: 14 } });
  });

  test('a live subscription keeps Pro after the trial', async () => {
    const u = await registerUser();
    await endTrial(u);
    await addSubscription(u);
    expect(await me(u)).toMatchObject({ plan: 'pro', source: 'subscription', subscription: { provider: 'paddle', status: 'active' } });
  });

  test('past_due within the period still counts; canceled or long-expired does not', async () => {
    const pastDue = await registerUser();
    await endTrial(pastDue);
    await addSubscription(pastDue, { status: 'past_due' });
    expect((await me(pastDue)).plan).toBe('pro');

    const canceled = await registerUser();
    await endTrial(canceled);
    await addSubscription(canceled, { status: 'canceled' });
    expect((await me(canceled)).plan).toBe('free');

    const expired = await registerUser();
    await endTrial(expired);
    await addSubscription(expired, { periodEnd: "now() - interval '5 days'" });
    expect((await me(expired)).plan).toBe('free');
  });

  test('a renewal webhook a day late does not downgrade (3-day grace)', async () => {
    const u = await registerUser();
    await endTrial(u);
    await addSubscription(u, { periodEnd: "now() - interval '1 day'" });
    expect((await me(u)).plan).toBe('pro');
  });

  test('admins are always Pro', async () => {
    const admin = await adminUser();
    await query(`UPDATE users SET trial_ends_at = now() - interval '1 day' WHERE email = 'admin@test.local'`);
    expect(await me(admin)).toMatchObject({ plan: 'pro', source: 'admin' });
  });
});

describe('limits', () => {
  test('Free: the 4th project → 402 with a translated message; nothing is deleted', async () => {
    const u = await registerUser();
    for (let i = 0; i < 4; i++) await createProject(u, `P${i}`).expect(201); // created during the trial
    await endTrial(u);

    const res = await createProject(u).set('Accept-Language', 'en').expect(402);
    expect(res.body).toMatchObject({ code: 'plan.projectLimit', details: { limit: 'projects', max: 3 } });
    expect(res.body.error).toMatch(/Pro/);

    const list = await api().get('/api/v1/projects').set(u.auth).expect(200);
    expect(list.body).toHaveLength(4);
  });

  test('Pro: no project limit', async () => {
    const u = await registerUser();
    for (let i = 0; i < 5; i++) await createProject(u, `P${i}`).expect(201);
  });

  test('Free: plans older than 14 days are hidden (not deleted) and come back with Pro', async () => {
    const u = await registerUser();
    const project = (await createProject(u).expect(201)).body;
    const plan = (d) => api().post('/api/v1/plans').set(u.auth).send({ project_id: project.id, date: d, start_min: 600, end_min: 660 });
    await plan(daysAgo(30)).expect(201);
    await plan(daysAgo(2)).expect(201);

    const range = () => api().get('/api/v1/plans').set(u.auth).query({ from: daysAgo(40), to: daysAgo(0) });
    expect((await range().expect(200)).body).toHaveLength(2);

    await endTrial(u);
    const free = await range().expect(200);
    expect(free.body.map((p) => p.plan_date)).toEqual([daysAgo(2)]);
    expect(free.headers['x-history-start']).toBe(daysAgo(13));
    expect((await api().get('/api/v1/plans').set(u.auth).query({ date: daysAgo(30) }).expect(200)).body).toEqual([]);

    await addSubscription(u);
    const pro = await range().expect(200);
    expect(pro.body).toHaveLength(2);
    expect(pro.headers['x-history-start']).toBeUndefined();
  });
});

describe('admin', () => {
  test('grant and revoke promo Pro; stats count it separately from paying users', async () => {
    const { auth } = await adminUser();
    const u = await registerUser();
    await endTrial(u);

    await api().post(`/api/v1/admin/users/${u.user.id}/pro`).set(auth).send({ days: 30 }).expect(201);
    expect(await me(u)).toMatchObject({ plan: 'pro', source: 'promo' });

    const paying = await registerUser();
    await endTrial(paying);
    await addSubscription(paying);

    const stats = (await api().get('/api/v1/admin/stats').set(auth).expect(200)).body;
    const row = (id) => stats.users.find((x) => x.id === id);
    expect(row(u.user.id).plan_source).toBe('promo');
    expect(row(paying.user.id).plan_source).toBe('subscription');
    expect(stats.overview.billing.subscribers).toBeGreaterThanOrEqual(1);
    expect(stats.overview.billing.mrr_usd).toBeGreaterThanOrEqual(4.99);

    await api().delete(`/api/v1/admin/users/${u.user.id}/pro`).set(auth).expect(200);
    expect((await me(u)).plan).toBe('free');
  });

  test('regular users cannot grant Pro', async () => {
    const u = await registerUser();
    await api().post(`/api/v1/admin/users/${u.user.id}/pro`).set(u.auth).send({ days: 30 }).expect(403);
  });
});
