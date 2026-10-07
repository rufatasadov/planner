import jwt from 'jsonwebtoken';
import { query } from '../db.js';
import { HttpError } from '../utils/http.js';

export function signToken(user) {
  return jwt.sign({ sub: user.id, email: user.email }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
}

export async function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next(new HttpError(401, 'Avtorizasiya tələb olunur'));
  let payload;
  try {
    payload = jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    return next(new HttpError(401, 'Token etibarsızdır və ya vaxtı bitib'));
  }
  const { rowCount } = await query('SELECT 1 FROM users WHERE id = $1', [payload.sub]);
  if (!rowCount) return next(new HttpError(401, 'İstifadəçi tapılmadı'));
  req.userId = payload.sub;
  next();
}
