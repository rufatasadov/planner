import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { query } from '../db.js';
import { signToken, requireAuth } from '../middleware/auth.js';
import { HttpError, badRequest, conflict, requireString } from '../utils/http.js';

const router = Router();

const publicUser = (u) => ({ id: u.id, email: u.email, name: u.name, created_at: u.created_at });

router.post('/register', async (req, res) => {
  const email = requireString(req.body.email, 'email', { max: 255 }).toLowerCase();
  const name = requireString(req.body.name, 'name', { max: 255 });
  const password = req.body.password;
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw badRequest('Email düzgün deyil');
  if (typeof password !== 'string' || password.length < 6) {
    throw badRequest('Şifrə ən azı 6 simvol olmalıdır');
  }

  const exists = await query('SELECT 1 FROM users WHERE email = $1', [email]);
  if (exists.rowCount) throw conflict('Bu email artıq qeydiyyatdan keçib');

  const hash = await bcrypt.hash(password, 10);
  const { rows } = await query(
    'INSERT INTO users (email, name, password_hash) VALUES ($1, $2, $3) RETURNING *',
    [email, name, hash],
  );
  await query('INSERT INTO user_settings (user_id) VALUES ($1)', [rows[0].id]);

  res.status(201).json({ token: signToken(rows[0]), user: publicUser(rows[0]) });
});

router.post('/login', async (req, res) => {
  const email = requireString(req.body.email, 'email', { max: 255 }).toLowerCase();
  const password = String(req.body.password ?? '');

  const { rows } = await query('SELECT * FROM users WHERE email = $1', [email]);
  const user = rows[0];
  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    throw new HttpError(401, 'Email və ya şifrə yanlışdır');
  }
  res.json({ token: signToken(user), user: publicUser(user) });
});

router.get('/me', requireAuth, async (req, res) => {
  const { rows } = await query('SELECT * FROM users WHERE id = $1', [req.userId]);
  if (!rows[0]) throw new HttpError(401, 'İstifadəçi tapılmadı');
  res.json(publicUser(rows[0]));
});

export default router;
