import { Router } from 'express';
import { query } from '../db.js';
import { badRequest, notFound, requireDate, requireInt, requireString } from '../utils/http.js';
import { getOwnedTask } from './tasks.js';
import { getSettings } from './settings.js';

const router = Router();
const MAX_BODY = 20000;

const SELECT_NOTES = `
  SELECT n.id, n.task_id, n.plan_id, n.body, n.created_at, n.updated_at,
         t.title AS task_title, t.status AS task_status,
         p.id AS project_id, p.name AS project_name, p.color AS project_color,
         pl.plan_date, pl.start_min AS plan_start_min, pl.end_min AS plan_end_min
  FROM task_notes n
  JOIN tasks t ON t.id = n.task_id
  JOIN projects p ON p.id = t.project_id
  LEFT JOIN plans pl ON pl.id = n.plan_id`;

async function loadNote(userId, id) {
  const { rows } = await query(`${SELECT_NOTES} WHERE n.id = $1 AND n.user_id = $2`, [id, userId]);
  if (!rows[0]) throw notFound('note.notFound');
  return rows[0];
}

async function readPlanId(userId, value) {
  if (value === undefined || value === null) return null;
  const id = requireInt(value, 'plan_id');
  const { rowCount } = await query('SELECT 1 FROM plans WHERE id = $1 AND user_id = $2', [id, userId]);
  if (!rowCount) throw notFound('plan.notFound');
  return id;
}

// GET /notes?task_id=&project_id=&plan_id=&from=YYYY-MM-DD&to=YYYY-MM-DD&q=&limit=&offset=
// Dates are interpreted in the user's timezone. Newest first.
router.get('/', async (req, res) => {
  const params = [req.userId];
  const where = ['n.user_id = $1'];
  const add = (sql, value) => {
    params.push(value);
    where.push(sql.replace('?', `$${params.length}`));
  };
  if (req.query.task_id) add('n.task_id = ?', requireInt(req.query.task_id, 'task_id'));
  if (req.query.project_id) add('t.project_id = ?', requireInt(req.query.project_id, 'project_id'));
  if (req.query.plan_id) add('n.plan_id = ?', requireInt(req.query.plan_id, 'plan_id'));
  if (req.query.from || req.query.to) {
    const { timezone } = await getSettings(req.userId);
    params.push(timezone);
    const localDate = `(n.created_at AT TIME ZONE $${params.length})::date`;
    if (req.query.from) add(`${localDate} >= ?::date`, requireDate(req.query.from, 'from'));
    if (req.query.to) add(`${localDate} <= ?::date`, requireDate(req.query.to, 'to'));
  }
  if (req.query.q) {
    const q = requireString(req.query.q, 'q', { max: 200 });
    params.push(`%${q}%`);
    where.push(`(n.body ILIKE $${params.length} OR t.title ILIKE $${params.length})`);
  }
  const limit = req.query.limit ? requireInt(req.query.limit, 'limit', { min: 1, max: 500 }) : 200;
  const offset = req.query.offset ? requireInt(req.query.offset, 'offset', { min: 0 }) : 0;
  const { rows } = await query(
    `${SELECT_NOTES} WHERE ${where.join(' AND ')} ORDER BY n.created_at DESC LIMIT ${limit} OFFSET ${offset}`,
    params,
  );
  res.json(rows);
});

router.get('/:id', async (req, res) => {
  res.json(await loadNote(req.userId, requireInt(req.params.id, 'id')));
});

// POST /notes { task_id, body, plan_id? }
router.post('/', async (req, res) => {
  const taskId = requireInt(req.body.task_id, 'task_id');
  await getOwnedTask(req.userId, taskId);
  const body = requireString(req.body.body, 'body', { max: MAX_BODY });
  const planId = await readPlanId(req.userId, req.body.plan_id);
  const { rows } = await query(
    'INSERT INTO task_notes (user_id, task_id, plan_id, body) VALUES ($1, $2, $3, $4) RETURNING id',
    [req.userId, taskId, planId, body],
  );
  res.status(201).json(await loadNote(req.userId, rows[0].id));
});

// PUT /notes/:id { body?, plan_id? }
router.put('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const current = await loadNote(req.userId, id);
  if (req.body.body === undefined && req.body.plan_id === undefined) throw badRequest('validation.required', { name: 'body' });
  const body = req.body.body !== undefined ? requireString(req.body.body, 'body', { max: MAX_BODY }) : current.body;
  const planId = req.body.plan_id !== undefined ? await readPlanId(req.userId, req.body.plan_id) : current.plan_id;
  await query('UPDATE task_notes SET body = $2, plan_id = $3, updated_at = now() WHERE id = $1', [id, body, planId]);
  res.json(await loadNote(req.userId, id));
});

router.delete('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const { rowCount } = await query('DELETE FROM task_notes WHERE id = $1 AND user_id = $2', [id, req.userId]);
  if (!rowCount) throw notFound('note.notFound');
  res.status(204).end();
});

export default router;
