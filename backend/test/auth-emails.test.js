import { afterAll, describe, expect, test } from 'vitest';
import { pool, query } from '../src/db.js';
import { outbox } from '../src/services/mail.js';
import { api, registerUser } from './helpers.js';

afterAll(() => pool.end());

const lastMailTo = (email) => [...outbox].reverse().find((m) => m.to === email);
const tokenFrom = (mail, path) => new URL(mail.text.match(new RegExp(`https://app\\.test${path}\\?token=\\S+`))[0]).searchParams.get('token');

describe('email verification', () => {
  test('sign-up sends a verification link that confirms the email once', async () => {
    const u = await registerUser();
    expect(u.user.email_verified).toBe(false);

    const mail = lastMailTo(u.email);
    expect(mail.subject).toMatch(/confirm|təsdiq|подтверд/i);
    const token = tokenFrom(mail, '/verify-email');

    await api().post('/api/v1/auth/verify-email').send({ token }).expect(200);
    const me = await api().get('/api/v1/auth/me').set(u.auth).expect(200);
    expect(me.body.email_verified).toBe(true);

    const again = await api().post('/api/v1/auth/verify-email').send({ token }).expect(400);
    expect(again.body.code).toBe('auth.invalidLink');
  });

  test('the email language follows Accept-Language', async () => {
    const email = `ru-${Date.now()}@test.local`;
    await api().post('/api/v1/auth/register').set('Accept-Language', 'ru').send({ email, password: 'secret123', name: 'Иван' }).expect(201);
    expect(lastMailTo(email).subject).toBe('Подтвердите email');
  });

  test('resend is limited to one email per minute', async () => {
    const u = await registerUser();
    const res = await api().post('/api/v1/auth/resend-verification').set(u.auth).expect(429);
    expect(res.body.code).toBe('auth.resendTooSoon');

    await query(`UPDATE auth_tokens SET created_at = now() - interval '2 minutes' WHERE user_id = $1`, [u.user.id]);
    await api().post('/api/v1/auth/resend-verification').set(u.auth).expect(200);
  });

  test('a garbage or expired token is rejected', async () => {
    await api().post('/api/v1/auth/verify-email').send({ token: 'x'.repeat(43) }).expect(400);
    const u = await registerUser();
    const token = tokenFrom(lastMailTo(u.email), '/verify-email');
    await query(`UPDATE auth_tokens SET expires_at = now() - interval '1 second' WHERE user_id = $1`, [u.user.id]);
    await api().post('/api/v1/auth/verify-email').send({ token }).expect(400);
  });
});

describe('password reset', () => {
  test('answers the same for unknown emails and sends nothing', async () => {
    const before = outbox.length;
    await api().post('/api/v1/auth/forgot-password').send({ email: 'nobody@test.local' }).expect(200);
    expect(outbox.length).toBe(before);
  });

  test('reset link sets a new password, signs in and logs out old sessions', async () => {
    const u = await registerUser();
    await api().post('/api/v1/auth/forgot-password').send({ email: u.email.toUpperCase() }).expect(200);
    const token = tokenFrom(lastMailTo(u.email), '/reset-password');

    // Tokens carry second precision; make sure the old one is from an earlier second.
    await new Promise((r) => setTimeout(r, 1100));
    const res = await api().post('/api/v1/auth/reset-password').send({ token, password: 'new-secret' }).expect(200);
    expect(res.body.user.email_verified).toBe(true);
    await api().get('/api/v1/auth/me').set({ Authorization: `Bearer ${res.body.token}` }).expect(200);

    const old = await api().get('/api/v1/auth/me').set(u.auth).expect(401);
    expect(old.body.code).toBe('auth.sessionExpired');

    await api().post('/api/v1/auth/login').send({ email: u.email, password: u.password }).expect(401);
    await api().post('/api/v1/auth/login').send({ email: u.email, password: 'new-secret' }).expect(200);
    await api().post('/api/v1/auth/reset-password').send({ token, password: 'another1' }).expect(400);
  });

  test('rejects a short password without using up the link', async () => {
    const u = await registerUser();
    await api().post('/api/v1/auth/forgot-password').send({ email: u.email }).expect(200);
    const token = tokenFrom(lastMailTo(u.email), '/reset-password');
    await api().post('/api/v1/auth/reset-password').send({ token, password: '123' }).expect(400);
    await api().post('/api/v1/auth/reset-password').send({ token, password: 'long-enough' }).expect(200);
  });
});
