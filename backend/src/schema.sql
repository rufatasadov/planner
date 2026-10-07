CREATE TABLE IF NOT EXISTS users (
  id            SERIAL PRIMARY KEY,
  email         VARCHAR(255) NOT NULL UNIQUE,
  name          VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Times are stored as minutes from midnight (0..1440), so 24:00 = 1440.
CREATE TABLE IF NOT EXISTS user_settings (
  user_id            INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  work_start_min     INTEGER NOT NULL DEFAULT 540  CHECK (work_start_min BETWEEN 0 AND 1440),
  work_end_min       INTEGER NOT NULL DEFAULT 1440 CHECK (work_end_min BETWEEN 0 AND 1440),
  notify_before_min  INTEGER NOT NULL DEFAULT 10   CHECK (notify_before_min BETWEEN 0 AND 240),
  CHECK (work_start_min < work_end_min)
);

CREATE TABLE IF NOT EXISTS projects (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        VARCHAR(255) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  color       VARCHAR(16) NOT NULL DEFAULT '#6366f1',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_projects_user ON projects(user_id);

DO $$ BEGIN
  CREATE TYPE task_status AS ENUM ('todo', 'in_progress', 'done', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS tasks (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  project_id  INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title       VARCHAR(500) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  status      task_status NOT NULL DEFAULT 'todo',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tasks_project ON tasks(project_id);

CREATE TABLE IF NOT EXISTS plans (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  project_id  INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  plan_date   DATE NOT NULL,
  start_min   INTEGER NOT NULL CHECK (start_min BETWEEN 0 AND 1440),
  end_min     INTEGER NOT NULL CHECK (end_min BETWEEN 0 AND 1440),
  note        TEXT NOT NULL DEFAULT '',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (start_min < end_min)
);
CREATE INDEX IF NOT EXISTS idx_plans_user_date ON plans(user_id, plan_date);

CREATE TABLE IF NOT EXISTS plan_tasks (
  plan_id INTEGER NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  PRIMARY KEY (plan_id, task_id)
);
