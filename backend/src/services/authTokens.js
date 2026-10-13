import crypto from 'node:crypto';
import { query } from '../db.js';

const hash = (token) => crypto.createHash('sha256').update(token).digest('hex');

/** Issues a one-time token for an email link; only its hash is stored. */
export async function createToken(userId, kind, ttlMs) {
  const token = crypto.randomBytes(32).toString('base64url');
  await query(
    `INSERT INTO auth_tokens (user_id, kind, token_hash, expires_at)
     VALUES ($1, $2, $3, now() + make_interval(secs => $4))`,
    [userId, kind, hash(token), ttlMs / 1000],
  );
  return token;
}

/** Marks the token used and returns its user id, or null when it is unknown, used or expired. */
export async function consumeToken(token, kind) {
  if (typeof token !== 'string' || token.length < 20 || token.length > 100) return null;
  const { rows } = await query(
    `UPDATE auth_tokens SET used_at = now()
     WHERE token_hash = $1 AND kind = $2 AND used_at IS NULL AND expires_at > now()
     RETURNING user_id`,
    [hash(token), kind],
  );
  return rows[0]?.user_id ?? null;
}

/** True when a token of this kind was issued for the user within the last `seconds`. */
export async function issuedRecently(userId, kind, seconds) {
  const { rowCount } = await query(
    `SELECT 1 FROM auth_tokens WHERE user_id = $1 AND kind = $2 AND created_at > now() - make_interval(secs => $3)`,
    [userId, kind, seconds],
  );
  return rowCount > 0;
}
