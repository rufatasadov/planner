// Subtask progress columns for a query where the task table is aliased as `t`.
export const SUBTASK_COUNTS_SQL = `
  (SELECT count(*)::int FROM tasks s WHERE s.parent_id = t.id) AS subtask_count,
  (SELECT count(*)::int FROM tasks s WHERE s.parent_id = t.id AND s.status = 'done') AS subtask_done`;

/**
 * Keeps a parent's status in line with its subtasks: it becomes `done` once every subtask is
 * done/cancelled (and at least one is done), and is reopened as `in_progress` when a subtask reopens.
 * Returns { id, title, status, changed } or null when there is no parent.
 */
export async function syncParent(db, parentId) {
  if (!parentId) return null;
  const { rows } = await db.query(
    `SELECT p.id, p.title, p.status,
            count(s.id)::int AS total,
            count(s.id) FILTER (WHERE s.status IN ('done', 'cancelled'))::int AS closed,
            count(s.id) FILTER (WHERE s.status = 'done')::int AS done
     FROM tasks p LEFT JOIN tasks s ON s.parent_id = p.id
     WHERE p.id = $1
     GROUP BY p.id`,
    [parentId],
  );
  const p = rows[0];
  if (!p) return null;
  let status = p.status;
  if (p.total > 0 && p.closed === p.total && p.done > 0) status = 'done';
  else if (p.closed < p.total && p.status === 'done') status = 'in_progress';
  if (status !== p.status) {
    await db.query('UPDATE tasks SET status = $2, updated_at = now() WHERE id = $1', [p.id, status]);
  }
  return { id: p.id, title: p.title, status, changed: status !== p.status };
}
