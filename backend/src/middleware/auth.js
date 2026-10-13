import jwt from 'jsonwebtoken';
import { query } from '../db.js';
import { forbidden, unauthorized } from '../utils/http.js';

const ADMIN_EMAILS = (process.env.ADMIN_EMAILS || 'allforaze@gmail.com')
  .split(',')
  .map((e) => e.trim().toLowerCase())
  .filter(Boolean);

export const isAdminEmail = (email) => ADMIN_EMAILS.includes(String(email).toLowerCase());

export function signToken(user) {
  return jwt.sign({ sub: user.id, email: user.email }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
}

export async function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next(unauthorized('auth.required'));
  let payload;
  try {
    payload = jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    return next(unauthorized('auth.invalidToken'));
  }
  const { rows } = await query(
    `UPDATE users SET last_seen_at = CASE
       WHEN last_seen_at IS NULL OR last_seen_at < now() - interval '5 minutes' THEN now() ELSE last_seen_at END
     WHERE id = $1 RETURNING email, password_changed_at`,
    [payload.sub],
  );
  if (!rows[0]) return next(unauthorized('auth.userNotFound'));
  // A password reset logs out sessions whose token was issued before it.
  const changedAt = rows[0].password_changed_at;
  if (changedAt && payload.iat < Math.floor(changedAt.getTime() / 1000)) {
    return next(unauthorized('auth.sessionExpired'));
  }
  req.userId = payload.sub;
  req.userEmail = rows[0].email;
  next();
}

/** Must run after requireAuth. The email is read from the database, not from the token. */
export function requireAdmin(req, _res, next) {
  if (!isAdminEmail(req.userEmail)) return next(forbidden());
  next();
}
