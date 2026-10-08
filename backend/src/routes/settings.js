import { Router } from 'express';
import { query } from '../db.js';
import { badRequest, requireInt } from '../utils/http.js';

const router = Router();

const COLUMNS = [
  'work_start_min',
  'work_end_min',
  'notify_before_min',
  'auto_stop',
  'break_reminder_min',
  'idle_pause_min',
  'target_efficiency_pct',
  'timezone',
];

const INT_FIELDS = {
  work_start_min: { min: 0, max: 1440 },
  work_end_min: { min: 0, max: 1440 },
  notify_before_min: { min: 0, max: 240 },
  break_reminder_min: { min: 0, max: 240 },
  idle_pause_min: { min: 0, max: 240 },
  target_efficiency_pct: { min: 1, max: 100 },
};

export async function getSettings(userId, db = { query }) {
  const { rows } = await db.query(
    `INSERT INTO user_settings (user_id) VALUES ($1)
     ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
     RETURNING ${COLUMNS.join(', ')}`,
    [userId],
  );
  return rows[0];
}

router.get('/', async (req, res) => {
  res.json(await getSettings(req.userId));
});

router.put('/', async (req, res) => {
  const next = { ...(await getSettings(req.userId)) };
  const b = req.body;

  for (const [name, range] of Object.entries(INT_FIELDS)) {
    if (b[name] !== undefined) next[name] = requireInt(b[name], name, range);
  }
  if (b.auto_stop !== undefined) {
    if (typeof b.auto_stop !== 'boolean') throw badRequest('validation.boolean', { name: 'auto_stop' });
    next.auto_stop = b.auto_stop;
  }
  if (b.timezone !== undefined) {
    const { rowCount } = await query('SELECT 1 FROM pg_timezone_names WHERE name = $1', [String(b.timezone)]);
    if (!rowCount) throw badRequest('settings.timezone');
    next.timezone = b.timezone;
  }
  if (next.work_start_min >= next.work_end_min) throw badRequest('settings.workRange');

  const sets = COLUMNS.map((c, i) => `${c} = $${i + 2}`).join(', ');
  const { rows } = await query(
    `UPDATE user_settings SET ${sets} WHERE user_id = $1 RETURNING ${COLUMNS.join(', ')}`,
    [req.userId, ...COLUMNS.map((c) => next[c])],
  );
  res.json(rows[0]);
});

export default router;
