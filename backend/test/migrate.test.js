import fs from 'node:fs/promises';
import { afterAll, expect, test } from 'vitest';
import { migrate } from '../src/migrate.js';
import { pool, query } from '../src/db.js';

afterAll(() => pool.end());

test('re-running migrations is a no-op and every file is recorded once', async () => {
  const logs = [];
  await migrate({ log: (m) => logs.push(m) });
  expect(logs).toEqual([]);

  const files = (await fs.readdir(new URL('../src/migrations', import.meta.url))).filter((f) => f.endsWith('.sql'));
  const { rows } = await query('SELECT name FROM schema_migrations ORDER BY name');
  expect(rows.map((r) => r.name)).toEqual(files.sort());
});

test('baseline creates the core tables', async () => {
  const { rows } = await query(
    `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name`,
  );
  const tables = rows.map((r) => r.table_name);
  for (const t of ['users', 'user_settings', 'projects', 'tasks', 'plans', 'work_sessions', 'plan_tasks', 'task_notes']) {
    expect(tables).toContain(t);
  }
});
