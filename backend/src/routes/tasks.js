import { Router } from 'express';
import { query } from '../db.js';
import { notFound, requireInt, requireOneOf, requireString } from '../utils/http.js';
import { getOwnedProject } from './projects.js';

const router = Router();

export const TASK_STATUSES = ['todo', 'in_progress', 'done', 'cancelled'];

function readStatus(value) {
  if (value === undefined) return undefined;
  return requireOneOf(value, 'status', TASK_STATUSES);
}

async function getOwnedTask(userId, taskId) {
  const { rows } = await query('SELECT * FROM tasks WHERE id = $1 AND user_id = $2', [taskId, userId]);
  if (!rows[0]) throw notFound('task.notFound');
  return rows[0];
}

// GET /tasks?project_id=1&status=todo,in_progress
router.get('/', async (req, res) => {
  const params = [req.userId];
  let where = 'user_id = $1';
  if (req.query.project_id) {
    params.push(requireInt(req.query.project_id, 'project_id'));
    where += ` AND project_id = $${params.length}`;
  }
  if (req.query.status) {
    const statuses = String(req.query.status).split(',').map(readStatus);
    params.push(statuses);
    where += ` AND status = ANY($${params.length}::task_status[])`;
  }
  const { rows } = await query(`SELECT * FROM tasks WHERE ${where} ORDER BY created_at ASC`, params);
  res.json(rows);
});

router.post('/', async (req, res) => {
  const projectId = requireInt(req.body.project_id, 'project_id');
  await getOwnedProject(req.userId, projectId);
  const title = requireString(req.body.title, 'title');
  const description = req.body.description ? requireString(req.body.description, 'description', { max: 5000, allowEmpty: true }) : '';
  const status = readStatus(req.body.status) ?? 'todo';
  const { rows } = await query(
    `INSERT INTO tasks (user_id, project_id, title, description, status)
     VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [req.userId, projectId, title, description, status],
  );
  res.status(201).json(rows[0]);
});

router.get('/:id', async (req, res) => {
  res.json(await getOwnedTask(req.userId, requireInt(req.params.id, 'id')));
});

router.put('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const current = await getOwnedTask(req.userId, id);
  const title = req.body.title !== undefined ? requireString(req.body.title, 'title') : current.title;
  const description =
    req.body.description !== undefined
      ? requireString(req.body.description, 'description', { max: 5000, allowEmpty: true })
      : current.description;
  const status = readStatus(req.body.status) ?? current.status;
  const { rows } = await query(
    `UPDATE tasks SET title = $2, description = $3, status = $4, updated_at = now()
     WHERE id = $1 RETURNING *`,
    [id, title, description, status],
  );
  res.json(rows[0]);
});

router.patch('/:id/status', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  await getOwnedTask(req.userId, id);
  const status = requireOneOf(req.body.status, 'status', TASK_STATUSES);
  const { rows } = await query('UPDATE tasks SET status = $2, updated_at = now() WHERE id = $1 RETURNING *', [id, status]);
  res.json(rows[0]);
});

router.delete('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const { rowCount } = await query('DELETE FROM tasks WHERE id = $1 AND user_id = $2', [id, req.userId]);
  if (!rowCount) throw notFound('task.notFound');
  res.status(204).end();
});

export default router;
