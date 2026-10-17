import { afterAll, describe, expect, test } from 'vitest';
import { pool, query } from '../src/db.js';
import { adminUser, api, registerUser } from './helpers.js';

afterAll(() => pool.end());

test('health', async () => {
  const res = await api().get('/api/v1/health').expect(200);
  expect(res.body).toEqual({ ok: true });
});

describe('auth', () => {
  test('register → login → me', async () => {
    const u = await registerUser();
    expect(u.token).toBeTruthy();
    expect(u.user).toMatchObject({ email: u.email, is_admin: false });
    expect(u.user.password_hash).toBeUndefined();

    const login = await api().post('/api/v1/auth/login').send({ email: u.email.toUpperCase(), password: u.password }).expect(200);
    const me = await api().get('/api/v1/auth/me').set('Authorization', `Bearer ${login.body.token}`).expect(200);
    expect(me.body.id).toBe(u.user.id);
  });

  test('duplicate email → 409 with a translated message', async () => {
    const u = await registerUser();
    const res = await api()
      .post('/api/v1/auth/register')
      .set('Accept-Language', 'en')
      .send({ email: u.email, password: 'secret123', name: 'X' })
      .expect(409);
    expect(res.body.code).toBe('auth.emailTaken');
    expect(res.body.error).toMatch(/[a-z]/i);
  });

  test('wrong password → 401', async () => {
    const u = await registerUser();
    const res = await api().post('/api/v1/auth/login').send({ email: u.email, password: 'nope-nope' }).expect(401);
    expect(res.body.code).toBe('auth.wrongCredentials');
  });

  test('protected routes need a valid token', async () => {
    await api().get('/api/v1/projects').expect(401);
    await api().get('/api/v1/projects').set('Authorization', 'Bearer garbage').expect(401);
  });

  test('admin panel is only for ADMIN_EMAILS', async () => {
    const user = await registerUser();
    await api().get('/api/v1/admin/stats').set(user.auth).expect(403);

    const admin = await adminUser();
    expect(admin.user.is_admin).toBe(true);
    await api().get('/api/v1/admin/stats').set(admin.auth).expect(200);
  });
});

describe('data isolation', () => {
  test("a user can't read or change another user's project", async () => {
    const alice = await registerUser();
    const bob = await registerUser();

    const created = await api().post('/api/v1/projects').set(alice.auth).send({ name: 'Alice project' }).expect(201);
    const id = created.body.id;

    const bobList = await api().get('/api/v1/projects').set(bob.auth).expect(200);
    expect(bobList.body.map((p) => p.id)).not.toContain(id);
    await api().get(`/api/v1/projects/${id}`).set(bob.auth).expect(404);
    await api().put(`/api/v1/projects/${id}`).set(bob.auth).send({ name: 'hacked' }).expect(404);
    await api().delete(`/api/v1/projects/${id}`).set(bob.auth).expect(404);

    const mine = await api().get(`/api/v1/projects/${id}`).set(alice.auth).expect(200);
    expect(mine.body.name).toBe('Alice project');
  });
});

describe('delete account', () => {
  test('the wrong password does not delete the account', async () => {
    const u = await registerUser();
    const res = await api().delete('/api/v1/auth/me').set(u.auth).send({ password: 'nope-nope' }).expect(401);
    expect(res.body.code).toBe('auth.wrongCredentials');
    await api().get('/api/v1/auth/me').set(u.auth).expect(200);
  });

  test('the right password deletes the user and their data', async () => {
    const u = await registerUser();
    await api().post('/api/v1/projects').set(u.auth).send({ name: 'gone' }).expect(201);
    await api().delete('/api/v1/auth/me').set(u.auth).send({ password: u.password }).expect(200);
    await api().get('/api/v1/auth/me').set(u.auth).expect(401);
    const { rows } = await query('SELECT count(*)::int AS n FROM users WHERE id = $1', [u.user.id]);
    expect(rows[0].n).toBe(0);
    const projects = await query('SELECT count(*)::int AS n FROM projects WHERE user_id = $1', [u.user.id]);
    expect(projects.rows[0].n).toBe(0);
  });
});
