#!/usr/bin/env bash
# Exports all data (no schema) from the planner Postgres container into a SQL file.
# Usage: ./scripts/db-export.sh [output-file]
set -euo pipefail

CONTAINER="${DB_CONTAINER:-planner-db}"
DB_USER="${DB_USER:-planner}"
DB_NAME="${DB_NAME:-planner}"
OUT="${1:-planner-data-$(date +%Y%m%d-%H%M%S).sql}"

docker exec "$CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" \
  --data-only --no-owner --no-privileges --schema=public > "$OUT"

echo "Exported to $OUT"
docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -Atc "
  SELECT 'users: ' || count(*) FROM users UNION ALL
  SELECT 'projects: ' || count(*) FROM projects UNION ALL
  SELECT 'tasks: ' || count(*) FROM tasks UNION ALL
  SELECT 'plans: ' || count(*) FROM plans"
