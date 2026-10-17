import { generateKeyPairSync } from 'node:crypto';
import { afterAll, beforeAll, expect, test } from 'vitest';
import jwt from 'jsonwebtoken';
import { pool, query } from '../src/db.js';
import { clearOAuthCache } from '../src/services/oauth.js';
import { api, registerUser } from './helpers.js';

const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = publicKey.export({ format: 'jwk' });
jwk.kid = 'test-key';
jwk.alg = 'RS256';
jwk.use = 'sig';

const originalFetch = globalThis.fetch;

function sign(provider, claims) {
  const apple = provider === 'apple';
  return jwt.sign(claims, privateKey, {
    algorithm: 'RS256',
    keyid: 'test-key',
    expiresIn: '5m',
    issuer: apple ? 'https://appleid.apple.com' : 'https://accounts.google.com',
    audience: apple ? 'com.onelineplanner.app' : 'test-google-client',
  });
}

beforeAll(() => {
  process.env.APPLE_CLIENT_IDS = 'com.onelineplanner.app';
  process.env.GOOGLE_CLIENT_IDS = 'test-google-client';
  clearOAuthCache();
  globalThis.fetch = async (url) => {
    const target = String(url);
    if (target.includes('tokeninfo')) {
      const token = new URL(target).searchParams.get('access_token');
      if (token !== 'good-access') return { ok: false, json: async () => ({}) };
      return {
        ok: true,
        json: async () => ({
          aud: 'test-google-client',
          sub: 'google-access-sub',
          email: 'access@test.local',
          email_verified: 'true',
        }),
      };
    }
    return { ok: true, json: async () => ({ keys: [jwk] }) };
  };
});

afterAll(async () => {
  globalThis.fetch = originalFetch;
  clearOAuthCache();
  await pool.end();
});

test('apple sign-in creates a verified account without a password', async () => {
  const token = sign('apple', { sub: 'apple-sub-1', email: 'Ada@test.local', email_verified: 'true' });
  const res = await api()
    .post('/api/v1/auth/oauth')
    .send({ provider: 'apple', id_token: token, name: 'Ada Lovelace' })
    .expect(200);

  expect(res.body.user).toMatchObject({
    email: 'ada@test.local',
    name: 'Ada Lovelace',
    email_verified: true,
    has_password: false,
  });
  expect(res.body.user.billing.source).toBe('trial');
  expect(res.body.user.password_hash).toBeUndefined();

  const again = sign('apple', { sub: 'apple-sub-1' });
  const second = await api().post('/api/v1/auth/oauth').send({ provider: 'apple', id_token: again }).expect(200);
  expect(second.body.user.id).toBe(res.body.user.id);

  await api().post('/api/v1/auth/login').send({ email: 'ada@test.local', password: 'secret123' }).expect(401);
  await api().delete('/api/v1/auth/me').set('Authorization', `Bearer ${res.body.token}`).send({}).expect(400);
  await api()
    .delete('/api/v1/auth/me')
    .set('Authorization', `Bearer ${res.body.token}`)
    .send({ confirm: true })
    .expect(200);
});

test('google sign-in with the same verified email joins the password account', async () => {
  const user = await registerUser({ email: 'linked@test.local' });
  const token = sign('google', { sub: 'google-sub-1', email: 'linked@test.local', email_verified: true });
  const res = await api().post('/api/v1/auth/oauth').send({ provider: 'google', id_token: token }).expect(200);
  expect(res.body.user.id).toBe(user.user.id);
  expect(res.body.user.has_password).toBe(true);

  const { rows } = await query(
    'SELECT provider, subject FROM user_identities WHERE user_id = $1',
    [user.user.id],
  );
  expect(rows).toEqual([{ provider: 'google', subject: 'google-sub-1' }]);
});

test('a google access token is accepted only when Google says it is ours', async () => {
  const res = await api()
    .post('/api/v1/auth/oauth')
    .send({ provider: 'google', access_token: 'good-access', name: 'Access User' })
    .expect(200);
  expect(res.body.user.email).toBe('access@test.local');

  await api().post('/api/v1/auth/oauth').send({ provider: 'google', access_token: 'bad-access' }).expect(401);
  await api().post('/api/v1/auth/oauth').send({ provider: 'apple', id_token: 'not-a-jwt' }).expect(401);
});

test('oauth stays off when the provider is not configured', async () => {
  const previous = process.env.GOOGLE_CLIENT_IDS;
  process.env.GOOGLE_CLIENT_IDS = '';
  clearOAuthCache();
  const token = sign('google', { sub: 'nobody', email: 'nobody@test.local', email_verified: true });
  await api().post('/api/v1/auth/oauth').send({ provider: 'google', id_token: token }).expect(503);
  process.env.GOOGLE_CLIENT_IDS = previous;
});
