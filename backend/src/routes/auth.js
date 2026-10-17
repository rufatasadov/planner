import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { query } from '../db.js';
import { isAdminEmail, signToken, requireAuth } from '../middleware/auth.js';
import { HttpError, badRequest, conflict, requireString, unauthorized } from '../utils/http.js';
import { TRIAL_DAYS, getBilling } from '../services/billing.js';
import { consumeToken, createToken, issuedRecently } from '../services/authTokens.js';
import { appUrl, sendMail } from '../services/mail.js';
import { resetPasswordMail, verifyEmailMail } from '../services/emails.js';
import { pickLanguage } from '../i18n.js';
import { reportError } from '../sentry.js';
import { signInWithOAuth, verifyGoogleAccessToken, verifyIdToken } from '../services/oauth.js';

const router = Router();

const VERIFY_TTL_MS = 3 * 24 * 3600_000;
const RESET_TTL_MS = 3600_000;
// Minimum gap between two emails of the same kind to one account.
const RESEND_COOLDOWN_SEC = 60;

const publicUser = async (u) => ({
  id: u.id,
  email: u.email,
  name: u.name,
  created_at: u.created_at,
  email_verified: Boolean(u.email_verified_at),
  has_password: Boolean(u.password_hash),
  is_admin: isAdminEmail(u.email),
  billing: await getBilling(u.id, u.email),
});

const session = async (user) => ({ token: signToken(user), user: await publicUser(user) });

function checkPassword(password) {
  if (typeof password !== 'string' || password.length < 6) throw badRequest('auth.passwordTooShort');
  if (password.length > 200) throw badRequest('validation.tooLong', { name: 'password' });
  return password;
}

async function sendVerification(user, lang) {
  const token = await createToken(user.id, 'verify_email', VERIFY_TTL_MS);
  const link = `${appUrl()}/verify-email?token=${token}`;
  await sendMail({ to: user.email, ...verifyEmailMail(lang, user.name, link) });
}

// A failed email must not fail the request that triggered it (sign-up, "forgot password").
const reportMailError = (req) => (err) => {
  console.error(err);
  reportError(err, req);
};

router.post('/register', async (req, res) => {
  const email = requireString(req.body.email, 'email', { max: 255 }).toLowerCase();
  const name = requireString(req.body.name, 'name', { max: 255 });
  const password = checkPassword(req.body.password);
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw badRequest('auth.invalidEmail');

  const exists = await query('SELECT 1 FROM users WHERE email = $1', [email]);
  if (exists.rowCount) throw conflict('auth.emailTaken');

  const hash = await bcrypt.hash(password, 10);
  const { rows } = await query(
    `INSERT INTO users (email, name, password_hash, trial_ends_at)
     VALUES ($1, $2, $3, now() + make_interval(days => $4)) RETURNING *`,
    [email, name, hash, TRIAL_DAYS],
  );
  await query('INSERT INTO user_settings (user_id) VALUES ($1)', [rows[0].id]);
  await sendVerification(rows[0], pickLanguage(req.headers['accept-language'])).catch(reportMailError(req));

  res.status(201).json(await session(rows[0]));
});

router.post('/login', async (req, res) => {
  const email = requireString(req.body.email, 'email', { max: 255 }).toLowerCase();
  const password = String(req.body.password ?? '');

  const { rows } = await query('SELECT * FROM users WHERE email = $1', [email]);
  const user = rows[0];
  if (!user?.password_hash || !(await bcrypt.compare(password, user.password_hash))) {
    throw unauthorized('auth.wrongCredentials');
  }
  res.json(await session(user));
});

// Apple (web + iOS) and Google (web + Android). A verified email joins an existing account.
router.post('/oauth', async (req, res) => {
  const provider = requireString(req.body.provider, 'provider', { max: 20 });
  if (provider !== 'apple' && provider !== 'google') throw badRequest('validation.required', { name: 'provider' });
  const name = typeof req.body.name === 'string' ? req.body.name.trim().slice(0, 255) : '';

  let claims;
  if (provider === 'google' && typeof req.body.access_token === 'string' && req.body.access_token) {
    if (req.body.access_token.length > 20000) throw badRequest('validation.tooLong', { name: 'access_token' });
    claims = await verifyGoogleAccessToken(req.body.access_token);
  } else {
    const idToken = requireString(req.body.id_token, 'id_token', { max: 20000 });
    claims = await verifyIdToken(provider, idToken);
  }
  claims.name = name;

  const user = await signInWithOAuth(claims);
  res.json(await session(user));
});

router.get('/me', requireAuth, async (req, res) => {
  const { rows } = await query('SELECT * FROM users WHERE id = $1', [req.userId]);
  if (!rows[0]) throw unauthorized('auth.userNotFound');
  res.json(await publicUser(rows[0]));
});

// Apple requires account deletion from inside the app. Related rows cascade from users.
router.delete('/me', requireAuth, async (req, res) => {
  const password = String(req.body?.password ?? '');
  if (password.length > 200) throw badRequest('validation.tooLong', { name: 'password' });

  const { rows } = await query('SELECT * FROM users WHERE id = $1', [req.userId]);
  const user = rows[0];
  if (!user) throw unauthorized('auth.userNotFound');
  if (user.password_hash) {
    if (!password || !(await bcrypt.compare(password, user.password_hash))) {
      throw unauthorized('auth.wrongCredentials');
    }
  } else if (req.body?.confirm !== true) {
    throw badRequest('validation.required', { name: 'confirm' });
  }

  await query('DELETE FROM users WHERE id = $1', [user.id]);
  res.json({ ok: true });
});

router.post('/verify-email', async (req, res) => {
  const userId = await consumeToken(req.body.token, 'verify_email');
  if (!userId) throw badRequest('auth.invalidLink');
  await query('UPDATE users SET email_verified_at = COALESCE(email_verified_at, now()) WHERE id = $1', [userId]);
  res.json({ ok: true });
});

router.post('/resend-verification', requireAuth, async (req, res) => {
  const { rows } = await query('SELECT * FROM users WHERE id = $1', [req.userId]);
  const user = rows[0];
  if (user.email_verified_at) return res.json({ ok: true, already_verified: true });
  if (await issuedRecently(user.id, 'verify_email', RESEND_COOLDOWN_SEC)) {
    throw new HttpError(429, 'auth.resendTooSoon');
  }
  await sendVerification(user, pickLanguage(req.headers['accept-language']));
  res.json({ ok: true });
});

// Always answers the same way, so it cannot be used to find out which emails have accounts.
router.post('/forgot-password', async (req, res) => {
  const email = requireString(req.body.email, 'email', { max: 255 }).toLowerCase();
  const { rows } = await query('SELECT * FROM users WHERE email = $1', [email]);
  const user = rows[0];
  if (user && !(await issuedRecently(user.id, 'reset_password', RESEND_COOLDOWN_SEC))) {
    const token = await createToken(user.id, 'reset_password', RESET_TTL_MS);
    const link = `${appUrl()}/reset-password?token=${token}`;
    const lang = pickLanguage(req.headers['accept-language']);
    await sendMail({ to: user.email, ...resetPasswordMail(lang, user.name, link) }).catch(reportMailError(req));
  }
  res.json({ ok: true });
});

// Sets the new password, logs out every other session and signs this browser in.
router.post('/reset-password', async (req, res) => {
  const password = checkPassword(req.body.password);
  const userId = await consumeToken(req.body.token, 'reset_password');
  if (!userId) throw badRequest('auth.invalidLink');

  const hash = await bcrypt.hash(password, 10);
  const { rows } = await query(
    `UPDATE users SET password_hash = $2, password_changed_at = now(),
       email_verified_at = COALESCE(email_verified_at, now())
     WHERE id = $1 RETURNING *`,
    [userId, hash],
  );
  await query(
    `UPDATE auth_tokens SET used_at = now() WHERE user_id = $1 AND kind = 'reset_password' AND used_at IS NULL`,
    [userId],
  );
  res.json(await session(rows[0]));
});

export default router;
