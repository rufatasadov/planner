export const STATUSES = [
  { value: 'todo', color: '#94a3b8' },
  { value: 'in_progress', color: '#f59e0b' },
  { value: 'done', color: '#22c55e' },
  { value: 'cancelled', color: '#ef4444' },
];

export const statusMeta = (value) => STATUSES.find((s) => s.value === value) ?? STATUSES[0];

export const PROJECT_COLORS = [
  '#6366f1', '#8b5cf6', '#ec4899', '#ef4444', '#f97316',
  '#f59e0b', '#22c55e', '#14b8a6', '#06b6d4', '#3b82f6',
];
