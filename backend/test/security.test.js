import { afterAll, beforeAll, expect, test } from 'vitest';
import { pool } from '../src/db.js';

let api;
beforeAll(async () => {
  // Limits are read when the app is created; a separate app keeps the other test files unaffected.
  process.env.AUTH_RATE_LIMIT = '3';
  process.env.CORS_ORIGIN = 'https://app.example.com, capacitor://localhost';
  const request = (await import('supertest')).default;
  const { createApp } = await import('../src/app.js');
  const app = createApp();
  api = () => request(app);
});
afterAll(() => pool.end());

test('security headers are set and x-powered-by is hidden', async () => {
  const res = await api().get('/api/v1/health').expect(200);
  expect(res.headers['x-content-type-options']).toBe('nosniff');
  expect(res.headers['x-powered-by']).toBeUndefined();
});

test('CORS allows only listed origins', async () => {
  const ok = await api().get('/api/v1/health').set('Origin', 'capacitor://localhost');
  expect(ok.headers['access-control-allow-origin']).toBe('capacitor://localhost');
  const bad = await api().get('/api/v1/health').set('Origin', 'https://evil.example');
  expect(bad.headers['access-control-allow-origin']).toBeUndefined();
});

test('malformed JSON → 400, oversized body → 413', async () => {
  const bad = await api().post('/api/v1/auth/login').set('Content-Type', 'application/json').send('{"email":');
  expect(bad.status).toBe(400);
  expect(bad.body.code).toBe('validation.json');

  const big = await api().post('/api/v1/auth/login').send({ email: 'a@b.c', password: 'x'.repeat(1_100_000) });
  expect(big.status).toBe(413);
});

test('login is rate limited per IP', async () => {
  const attempt = () => api().post('/api/v1/auth/login').send({ email: 'nobody@test.local', password: 'wrong-pass' });
  for (let i = 0; i < 3; i++) expect((await attempt()).status).toBe(401);
  const blocked = await attempt().set('Accept-Language', 'az');
  expect(blocked.status).toBe(429);
  expect(blocked.body.code).toBe('common.tooManyRequests');
  expect(blocked.body.error).toMatch(/sorğu/);
});
