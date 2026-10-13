import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { query } from '../db.js';
import { isAdminEmail, signToken, requireAuth } from '../middleware/auth.js';
import { badRequest, conflict, requireString, unauthorized } from '../utils/http.js';
import { TRIAL_DAYS, getBilling } from '../services/billing.js';

const router = Router();

const publicUser = async (u) => ({
  id: u.id,
  email: u.email,
  name: u.name,
  created_at: u.created_at,
  is_admin: isAdminEmail(u.email),
  billing: await getBilling(u.id, u.email),
});

router.post('/register', async (req, res) => {
  const email = requireString(req.body.email, 'email', { max: 255 }).toLowerCase();
  const name = requireString(req.body.name, 'name', { max: 255 });
  const password = req.body.password;
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw badRequest('auth.invalidEmail');
  if (typeof password !== 'string' || password.length < 6) {
    throw badRequest('auth.passwordTooShort');
  }

  const exists = await query('SELECT 1 FROM users WHERE email = $1', [email]);
  if (exists.rowCount) throw conflict('auth.emailTaken');

  const hash = await bcrypt.hash(password, 10);
  const { rows } = await query(
    `INSERT INTO users (email, name, password_hash, trial_ends_at)
     VALUES ($1, $2, $3, now() + make_interval(days => $4)) RETURNING *`,
    [email, name, hash, TRIAL_DAYS],
  );
  await query('INSERT INTO user_settings (user_id) VALUES ($1)', [rows[0].id]);

  res.status(201).json({ token: signToken(rows[0]), user: await publicUser(rows[0]) });
});

router.post('/login', async (req, res) => {
  const email = requireString(req.body.email, 'email', { max: 255 }).toLowerCase();
  const password = String(req.body.password ?? '');

  const { rows } = await query('SELECT * FROM users WHERE email = $1', [email]);
  const user = rows[0];
  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    throw unauthorized('auth.wrongCredentials');
  }
  res.json({ token: signToken(user), user: await publicUser(user) });
});

router.get('/me', requireAuth, async (req, res) => {
  const { rows } = await query('SELECT * FROM users WHERE id = $1', [req.userId]);
  if (!rows[0]) throw unauthorized('auth.userNotFound');
  res.json(await publicUser(rows[0]));
});

export default router;
