import { createPublicKey } from 'node:crypto';
import jwt from 'jsonwebtoken';
import { withTransaction } from '../db.js';
import { TRIAL_DAYS } from './billing.js';
import { HttpError, badRequest, unauthorized } from '../utils/http.js';

const APPLE_BUNDLE_ID = 'com.onelineplanner.app';

const PROVIDERS = {
  apple: {
    jwks: 'https://appleid.apple.com/auth/keys',
    issuers: ['https://appleid.apple.com'],
    env: 'APPLE_CLIENT_IDS',
    fallback: [APPLE_BUNDLE_ID],
  },
  google: {
    jwks: 'https://www.googleapis.com/oauth2/v3/certs',
    issuers: ['https://accounts.google.com', 'accounts.google.com'],
    env: 'GOOGLE_CLIENT_IDS',
    fallback: [],
  },
};

const keyCache = new Map();

export function clearOAuthCache() {
  keyCache.clear();
}

function clientIds(provider) {
  const spec = PROVIDERS[provider];
  const raw = process.env[spec.env];
  if (!raw || !raw.trim()) return spec.fallback;
  return raw.split(',').map((id) => id.trim()).filter(Boolean);
}

function emailOf(payload) {
  const verified = payload.email_verified === true || payload.email_verified === 'true';
  if (!verified || typeof payload.email !== 'string') return null;
  const email = payload.email.trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return null;
  return email;
}

async function jwks(url, fetchImpl, now) {
  const hit = keyCache.get(url);
  if (hit && hit.until > now()) return hit.keys;
  const res = await fetchImpl(url);
  if (!res.ok) throw new HttpError(503, 'auth.oauthUnavailable');
  const body = await res.json();
  const keys = new Map((body.keys || []).filter((key) => key.kid).map((key) => [key.kid, key]));
  keyCache.set(url, { keys, until: now() + 60 * 60 * 1000 });
  return keys;
}

/** Verifies an Apple or Google ID token. Email is returned only when the provider says it is verified. */
export async function verifyIdToken(provider, token, { fetchImpl = fetch, now = Date.now } = {}) {
  const spec = PROVIDERS[provider];
  const audiences = clientIds(provider);
  if (!spec || !audiences.length) throw new HttpError(503, 'auth.oauthUnavailable');

  const headerPart = String(token).split('.')[0];
  let header;
  try {
    header = JSON.parse(Buffer.from(headerPart, 'base64url').toString());
  } catch {
    throw unauthorized('auth.oauthInvalid');
  }
  const keys = await jwks(spec.jwks, fetchImpl, now);
  const jwk = keys.get(header.kid);
  if (!jwk) throw unauthorized('auth.oauthInvalid');

  let payload;
  try {
    const key = createPublicKey({ key: jwk, format: 'jwk' });
    payload = jwt.verify(token, key, { algorithms: ['RS256'], audience: audiences, issuer: spec.issuers });
  } catch {
    throw unauthorized('auth.oauthInvalid');
  }
  if (!payload.sub) throw unauthorized('auth.oauthInvalid');
  return { provider, subject: String(payload.sub), email: emailOf(payload), name: '' };
}

/** Web Google sign-in sends an access token from the account chooser. It is checked with Google, not trusted as-is. */
export async function verifyGoogleAccessToken(accessToken, { fetchImpl = fetch } = {}) {
  const audiences = clientIds('google');
  if (!audiences.length) throw new HttpError(503, 'auth.oauthUnavailable');
  const res = await fetchImpl(
    `https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(accessToken)}`,
  );
  if (!res.ok) throw unauthorized('auth.oauthInvalid');
  const payload = await res.json();
  if (!audiences.includes(payload.aud) || !payload.sub) throw unauthorized('auth.oauthInvalid');
  return { provider: 'google', subject: String(payload.sub), email: emailOf(payload), name: '' };
}

/** Finds the user for this provider subject, links a verified email to an existing account, or creates one. */
export async function accountForIdentity({ provider, subject, email, name }) {
  return withTransaction(async (client) => {
    const found = await client.query(
      `SELECT u.* FROM user_identities i
       JOIN users u ON u.id = i.user_id
       WHERE i.provider = $1 AND i.subject = $2`,
      [provider, subject],
    );
    if (found.rows[0]) return found.rows[0];
    if (!email) throw badRequest('auth.oauthEmailRequired');

    const byEmail = await client.query('SELECT * FROM users WHERE email = $1', [email]);
    let user = byEmail.rows[0];
    if (!user) {
      const display = (name || email.split('@')[0] || 'User').slice(0, 255);
      const inserted = await client.query(
        `INSERT INTO users (email, name, password_hash, trial_ends_at, email_verified_at)
         VALUES ($1, $2, NULL, now() + make_interval(days => $3), now())
         RETURNING *`,
        [email, display, TRIAL_DAYS],
      );
      user = inserted.rows[0];
      await client.query('INSERT INTO user_settings (user_id) VALUES ($1) ON CONFLICT DO NOTHING', [user.id]);
    } else if (!user.email_verified_at) {
      const updated = await client.query(
        'UPDATE users SET email_verified_at = now() WHERE id = $1 RETURNING *',
        [user.id],
      );
      user = updated.rows[0];
    }
    await client.query(
      `INSERT INTO user_identities (user_id, provider, subject) VALUES ($1, $2, $3)
       ON CONFLICT (provider, subject) DO NOTHING`,
      [user.id, provider, subject],
    );
    return user;
  });
}

export async function signInWithOAuth(claims) {
  try {
    return await accountForIdentity(claims);
  } catch (err) {
    if (err.code !== '23505') throw err;
    return accountForIdentity(claims);
  }
}
