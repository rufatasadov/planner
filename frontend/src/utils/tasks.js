const byPosition = (a, b) => a.position - b.position || new Date(a.created_at ?? 0) - new Date(b.created_at ?? 0);

/**
 * Groups a flat task list into top-level tasks with `children` (one level deep).
 * Subtasks whose parent is not in the list are kept at the top level (they carry `parent_title`).
 */
export function buildTree(tasks) {
  const ids = new Set(tasks.map((t) => t.id));
  const children = new Map();
  const roots = [];
  for (const task of tasks) {
    if (task.parent_id && ids.has(task.parent_id)) {
      if (!children.has(task.parent_id)) children.set(task.parent_id, []);
      children.get(task.parent_id).push(task);
    } else {
      roots.push(task);
    }
  }
  return roots.sort(byPosition).map((task) => ({ task, children: (children.get(task.id) ?? []).sort(byPosition) }));
}

export function moveInList(list, fromId, toId, after) {
  const items = list.filter((x) => x.id !== fromId);
  const moved = list.find((x) => x.id === fromId);
  const index = items.findIndex((x) => x.id === toId) + (after ? 1 : 0);
  items.splice(index, 0, moved);
  return items;
}
