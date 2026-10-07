import { Router } from 'express';
import { query } from '../db.js';
import { badRequest, notFound, requireInt, requireString } from '../utils/http.js';

const router = Router();

const COLOR_RE = /^#[0-9a-fA-F]{6}$/;

const PROJECT_SELECT = `
  SELECT p.*,
    COUNT(t.id)::int AS task_count,
    COUNT(t.id) FILTER (WHERE t.status IN ('todo', 'in_progress'))::int AS open_task_count,
    COUNT(t.id) FILTER (WHERE t.status = 'done')::int AS done_task_count
  FROM projects p
  LEFT JOIN tasks t ON t.project_id = p.id
`;

export async function getOwnedProject(userId, projectId) {
  const { rows } = await query(`${PROJECT_SELECT} WHERE p.id = $1 AND p.user_id = $2 GROUP BY p.id`, [
    projectId,
    userId,
  ]);
  if (!rows[0]) throw notFound('project.notFound');
  return rows[0];
}

function readColor(value) {
  if (value === undefined) return undefined;
  if (typeof value !== 'string' || !COLOR_RE.test(value)) throw badRequest('project.color');
  return value;
}

router.get('/', async (req, res) => {
  const { rows } = await query(`${PROJECT_SELECT} WHERE p.user_id = $1 GROUP BY p.id ORDER BY p.created_at DESC`, [
    req.userId,
  ]);
  res.json(rows);
});

router.post('/', async (req, res) => {
  const name = requireString(req.body.name, 'name', { max: 255 });
  const description = req.body.description ? requireString(req.body.description, 'description', { max: 5000, allowEmpty: true }) : '';
  const color = readColor(req.body.color) ?? '#6366f1';
  const { rows } = await query(
    'INSERT INTO projects (user_id, name, description, color) VALUES ($1, $2, $3, $4) RETURNING id',
    [req.userId, name, description, color],
  );
  res.status(201).json(await getOwnedProject(req.userId, rows[0].id));
});

router.get('/:id', async (req, res) => {
  res.json(await getOwnedProject(req.userId, requireInt(req.params.id, 'id')));
});

router.put('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const current = await getOwnedProject(req.userId, id);
  const name = req.body.name !== undefined ? requireString(req.body.name, 'name', { max: 255 }) : current.name;
  const description =
    req.body.description !== undefined
      ? requireString(req.body.description, 'description', { max: 5000, allowEmpty: true })
      : current.description;
  const color = readColor(req.body.color) ?? current.color;
  await query('UPDATE projects SET name = $2, description = $3, color = $4 WHERE id = $1', [id, name, description, color]);
  res.json(await getOwnedProject(req.userId, id));
});

router.delete('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const { rowCount } = await query('DELETE FROM projects WHERE id = $1 AND user_id = $2', [id, req.userId]);
  if (!rowCount) throw notFound('project.notFound');
  res.status(204).end();
});

export default router;
