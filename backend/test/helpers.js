import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { createApp } from '../src/app.js';

export const app = createApp();
export const api = () => request(app);

export async function registerUser({ email = `user-${randomUUID()}@test.local`, password = 'secret123', name = 'Test' } = {}) {
  const res = await api().post('/api/v1/auth/register').send({ email, password, name }).expect(201);
  return { ...res.body, email, password, auth: { Authorization: `Bearer ${res.body.token}` } };
}

/** The single admin account (ADMIN_EMAILS in vitest.config.js), shared by all test files. */
export async function adminUser() {
  const creds = { email: 'admin@test.local', password: 'secret123' };
  const res = await api().post('/api/v1/auth/login').send(creds);
  if (res.status !== 200) return registerUser(creds);
  return { ...res.body, ...creds, auth: { Authorization: `Bearer ${res.body.token}` } };
}
