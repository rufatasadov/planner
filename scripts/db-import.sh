#!/usr/bin/env bash
# Imports a file produced by db-export.sh into the planner Postgres container.
# ALL existing data in the target database is replaced. Runs in a single transaction:
# if anything fails, the database is left untouched.
# Usage: ./scripts/db-import.sh <file.sql> [--yes]
set -euo pipefail

FILE="${1:?Usage: $0 <file.sql> [--yes]}"
CONTAINER="${DB_CONTAINER:-planner-db}"
DB_USER="${DB_USER:-planner}"
DB_NAME="${DB_NAME:-planner}"

[ -f "$FILE" ] || { echo "File not found: $FILE" >&2; exit 1; }

psql_exec() { docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" "$@"; }

if [ "$(psql_exec -Atc "SELECT to_regclass('public.users') IS NOT NULL")" != "t" ]; then
  echo "Tables do not exist yet. Start the backend once (docker compose up -d) so it creates the schema." >&2
  exit 1
fi

echo "Current data in '$DB_NAME' ($CONTAINER):"
psql_exec -Atc "SELECT '  users: ' || count(*) FROM users UNION ALL SELECT '  projects: ' || count(*) FROM projects UNION ALL SELECT '  tasks: ' || count(*) FROM tasks UNION ALL SELECT '  plans: ' || count(*) FROM plans"

if [ "${2:-}" != "--yes" ]; then
  read -r -p "This data will be DELETED and replaced with $FILE. Continue? [y/N] " answer
  [[ "$answer" =~ ^[yY]$ ]] || { echo "Aborted."; exit 1; }
fi

{
  echo "SET session_replication_role = replica;"
  echo "TRUNCATE users, user_settings, projects, tasks, plans, plan_tasks RESTART IDENTITY CASCADE;"
  cat "$FILE"
  echo "SET session_replication_role = DEFAULT;"
} | psql_exec -q -v ON_ERROR_STOP=1 --single-transaction > /dev/null

echo "Import completed:"
psql_exec -Atc "SELECT '  users: ' || count(*) FROM users UNION ALL SELECT '  projects: ' || count(*) FROM projects UNION ALL SELECT '  tasks: ' || count(*) FROM tasks UNION ALL SELECT '  plans: ' || count(*) FROM plans"
