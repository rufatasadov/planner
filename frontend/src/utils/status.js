export const STATUSES = [
  { value: 'todo', label: 'Gözləyir', color: '#94a3b8' },
  { value: 'in_progress', label: 'İcrada', color: '#f59e0b' },
  { value: 'done', label: 'Bitib', color: '#22c55e' },
  { value: 'cancelled', label: 'Ləğv edilib', color: '#ef4444' },
];

export const statusMeta = (value) => STATUSES.find((s) => s.value === value) ?? STATUSES[0];

export const PROJECT_COLORS = [
  '#6366f1', '#8b5cf6', '#ec4899', '#ef4444', '#f97316',
  '#f59e0b', '#22c55e', '#14b8a6', '#06b6d4', '#3b82f6',
];
