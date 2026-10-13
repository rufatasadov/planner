import pg from 'pg';

export async function setup() {
  const url = new URL(process.env.TEST_DATABASE_URL || 'postgres://planner:planner@localhost:5433/planner_test');
  const dbName = url.pathname.slice(1);
  if (!/test/.test(dbName)) throw new Error(`Refusing to recreate "${dbName}": test database name must contain "test"`);

  const adminUrl = new URL(url);
  adminUrl.pathname = '/postgres';
  const admin = new pg.Client({ connectionString: adminUrl.toString() });
  await admin.connect();
  await admin.query(`DROP DATABASE IF EXISTS "${dbName}" WITH (FORCE)`);
  await admin.query(`CREATE DATABASE "${dbName}"`);
  await admin.end();

  process.env.DATABASE_URL = url.toString();
  const { migrate } = await import('../src/migrate.js');
  const { pool } = await import('../src/db.js');
  await migrate({ log: () => {} });
  await pool.end();
}
