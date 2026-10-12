import { Router } from 'express';
import { query, withTransaction } from '../db.js';
import { badRequest, notFound, requireInt, requireOneOf, requireString } from '../utils/http.js';
import { getOwnedProject } from './projects.js';
import { SUBTASK_COUNTS_SQL, syncParent } from '../services/tasks.js';

const router = Router();

export const TASK_STATUSES = ['todo', 'in_progress', 'done', 'cancelled'];

const SELECT_TASKS = `
  SELECT t.*, parent.title AS parent_title,
         (SELECT count(*)::int FROM task_notes n WHERE n.task_id = t.id) AS note_count,
         ${SUBTASK_COUNTS_SQL}
  FROM tasks t LEFT JOIN tasks parent ON parent.id = t.parent_id`;

function readStatus(value) {
  if (value === undefined) return undefined;
  return requireOneOf(value, 'status', TASK_STATUSES);
}

export async function getOwnedTask(userId, taskId, db = { query }) {
  const { rows } = await db.query('SELECT * FROM tasks WHERE id = $1 AND user_id = $2', [taskId, userId]);
  if (!rows[0]) throw notFound('task.notFound');
  return rows[0];
}

async function loadTask(db, id) {
  const { rows } = await db.query(`${SELECT_TASKS} WHERE t.id = $1`, [id]);
  return rows[0];
}

/** Validates a parent for a (new or moved) task: a top-level task of the same project. */
async function checkParent(db, userId, parentId, projectId, taskId = null) {
  const parent = await getOwnedTask(userId, parentId, db);
  if (parent.id === taskId || parent.parent_id !== null || parent.project_id !== projectId) {
    throw badRequest('task.invalidParent');
  }
  return parent;
}

async function nextPosition(db, projectId, parentId) {
  const { rows } = await db.query(
    'SELECT COALESCE(MAX(position), -1) + 1 AS pos FROM tasks WHERE project_id = $1 AND parent_id IS NOT DISTINCT FROM $2',
    [projectId, parentId],
  );
  return rows[0].pos;
}

// GET /tasks?project_id=1&status=todo,in_progress&parent_id=5|null
router.get('/', async (req, res) => {
  const params = [req.userId];
  let where = 't.user_id = $1';
  if (req.query.project_id) {
    params.push(requireInt(req.query.project_id, 'project_id'));
    where += ` AND t.project_id = $${params.length}`;
  }
  if (req.query.parent_id === 'null') {
    where += ' AND t.parent_id IS NULL';
  } else if (req.query.parent_id) {
    params.push(requireInt(req.query.parent_id, 'parent_id'));
    where += ` AND t.parent_id = $${params.length}`;
  }
  if (req.query.status) {
    const statuses = String(req.query.status).split(',').map(readStatus);
    params.push(statuses);
    where += ` AND t.status = ANY($${params.length}::task_status[])`;
  }
  const { rows } = await query(`${SELECT_TASKS} WHERE ${where} ORDER BY t.position, t.created_at`, params);
  res.json(rows);
});

// POST /tasks { project_id?, parent_id?, title, description?, status? } — project_id may be omitted for subtasks.
router.post('/', async (req, res) => {
  const result = await withTransaction(async (db) => {
    let projectId = req.body.project_id !== undefined ? requireInt(req.body.project_id, 'project_id') : null;
    let parentId = null;
    if (req.body.parent_id !== undefined && req.body.parent_id !== null) {
      const parent = await getOwnedTask(req.userId, requireInt(req.body.parent_id, 'parent_id'), db);
      projectId ??= parent.project_id;
      parentId = (await checkParent(db, req.userId, parent.id, projectId)).id;
    }
    if (projectId === null) throw badRequest('validation.required', { name: 'project_id' });
    await getOwnedProject(req.userId, projectId);
    const title = requireString(req.body.title, 'title');
    const description = req.body.description
      ? requireString(req.body.description, 'description', { max: 5000, allowEmpty: true })
      : '';
    const status = readStatus(req.body.status) ?? 'todo';
    const position = await nextPosition(db, projectId, parentId);
    const { rows } = await db.query(
      `INSERT INTO tasks (user_id, project_id, parent_id, position, title, description, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      [req.userId, projectId, parentId, position, title, description, status],
    );
    const parent = await syncParent(db, parentId);
    return { ...(await loadTask(db, rows[0].id)), parent };
  });
  res.status(201).json(result);
});

// PUT /tasks/reorder { ids: [...] } — new order of sibling tasks (same project and parent).
router.put('/reorder', async (req, res) => {
  const ids = req.body.ids;
  if (!Array.isArray(ids) || !ids.length) throw badRequest('validation.required', { name: 'ids' });
  const taskIds = ids.map((id) => requireInt(id, 'ids'));
  await withTransaction(async (db) => {
    const { rows } = await db.query(
      'SELECT DISTINCT project_id, parent_id FROM tasks WHERE id = ANY($1::int[]) AND user_id = $2',
      [taskIds, req.userId],
    );
    const { rows: found } = await db.query('SELECT count(*)::int AS n FROM tasks WHERE id = ANY($1::int[]) AND user_id = $2', [
      taskIds,
      req.userId,
    ]);
    if (rows.length !== 1 || found[0].n !== new Set(taskIds).size) throw badRequest('task.reorderMismatch');
    await db.query(
      `UPDATE tasks t SET position = o.pos
       FROM unnest($1::int[]) WITH ORDINALITY AS o(id, pos)
       WHERE t.id = o.id`,
      [taskIds],
    );
  });
  res.json({ ok: true });
});

router.get('/:id', async (req, res) => {
  const task = await getOwnedTask(req.userId, requireInt(req.params.id, 'id'));
  res.json(await loadTask({ query }, task.id));
});

// PUT /tasks/:id { title?, description?, status?, parent_id? (null = make top-level) }
router.put('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const result = await withTransaction(async (db) => {
    const current = await getOwnedTask(req.userId, id, db);
    const title = req.body.title !== undefined ? requireString(req.body.title, 'title') : current.title;
    const description =
      req.body.description !== undefined
        ? requireString(req.body.description, 'description', { max: 5000, allowEmpty: true })
        : current.description;
    const status = readStatus(req.body.status) ?? current.status;

    let parentId = current.parent_id;
    let position = current.position;
    if (req.body.parent_id !== undefined) {
      parentId = req.body.parent_id === null ? null : requireInt(req.body.parent_id, 'parent_id');
      if (parentId !== current.parent_id) {
        if (parentId !== null) {
          await checkParent(db, req.userId, parentId, current.project_id, id);
          const { rowCount } = await db.query('SELECT 1 FROM tasks WHERE parent_id = $1 LIMIT 1', [id]);
          if (rowCount) throw badRequest('task.hasSubtasks');
        }
        position = await nextPosition(db, current.project_id, parentId);
      }
    }

    await db.query(
      `UPDATE tasks SET title = $2, description = $3, status = $4, parent_id = $5, position = $6, updated_at = now()
       WHERE id = $1`,
      [id, title, description, status, parentId, position],
    );
    const oldParent = parentId !== current.parent_id ? await syncParent(db, current.parent_id) : null;
    const parent = await syncParent(db, parentId);
    return { ...(await loadTask(db, id)), parent, old_parent: oldParent };
  });
  res.json(result);
});

router.patch('/:id/status', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const status = requireOneOf(req.body.status, 'status', TASK_STATUSES);
  const result = await withTransaction(async (db) => {
    const task = await getOwnedTask(req.userId, id, db);
    await db.query('UPDATE tasks SET status = $2, updated_at = now() WHERE id = $1', [id, status]);
    const parent = await syncParent(db, task.parent_id);
    return { ...(await loadTask(db, id)), parent };
  });
  res.json(result);
});

router.delete('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const parent = await withTransaction(async (db) => {
    const task = await getOwnedTask(req.userId, id, db);
    await db.query('DELETE FROM tasks WHERE id = $1', [id]);
    return syncParent(db, task.parent_id);
  });
  res.json({ ok: true, parent });
});

export default router;
