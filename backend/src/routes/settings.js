import { Router } from 'express';
import { query } from '../db.js';
import { badRequest, requireInt } from '../utils/http.js';

const router = Router();

export async function getSettings(userId) {
  const { rows } = await query(
    `INSERT INTO user_settings (user_id) VALUES ($1)
     ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
     RETURNING work_start_min, work_end_min, notify_before_min`,
    [userId],
  );
  return rows[0];
}

router.get('/', async (req, res) => {
  res.json(await getSettings(req.userId));
});

router.put('/', async (req, res) => {
  const current = await getSettings(req.userId);
  const b = req.body;
  const next = {
    work_start_min:
      b.work_start_min !== undefined
        ? requireInt(b.work_start_min, 'work_start_min', { min: 0, max: 1440 })
        : current.work_start_min,
    work_end_min:
      b.work_end_min !== undefined
        ? requireInt(b.work_end_min, 'work_end_min', { min: 0, max: 1440 })
        : current.work_end_min,
    notify_before_min:
      b.notify_before_min !== undefined
        ? requireInt(b.notify_before_min, 'notify_before_min', { min: 0, max: 240 })
        : current.notify_before_min,
  };
  if (next.work_start_min >= next.work_end_min) {
    throw badRequest('İş günü başlanğıcı bitişdən əvvəl olmalıdır');
  }
  const { rows } = await query(
    `UPDATE user_settings SET work_start_min = $2, work_end_min = $3, notify_before_min = $4
     WHERE user_id = $1 RETURNING work_start_min, work_end_min, notify_before_min`,
    [req.userId, next.work_start_min, next.work_end_min, next.notify_before_min],
  );
  res.json(rows[0]);
});

export default router;
