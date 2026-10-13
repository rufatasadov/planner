#!/usr/bin/env bash
# Proves a backup is usable: restores it into a scratch database, prints row counts, drops it.
# The live database is not touched.
# Usage: ./scripts/db-restore-test.sh [backups/planner-YYYYmmdd-HHMMSS.dump]   (default: newest)
set -euo pipefail

CONTAINER="${DB_CONTAINER:-planner-db}"
DB_USER="${DB_USER:-planner}"
SCRATCH="planner_restore_test"
DIR="$(cd "$(dirname "$0")/.." && pwd)/backups"

FILE="${1:-$(ls -1t "$DIR"/planner-*.dump 2>/dev/null | head -n1 || true)}"
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "No backup found (looked in $DIR)" >&2; exit 1; }

echo "Restoring $FILE into scratch database '$SCRATCH'..."
psql_admin() { docker exec -e PGOPTIONS='-c client_min_messages=warning' "$CONTAINER" psql -U "$DB_USER" -d postgres -q "$@"; }
psql_admin -c "DROP DATABASE IF EXISTS $SCRATCH WITH (FORCE)" -c "CREATE DATABASE $SCRATCH"
trap 'psql_admin -c "DROP DATABASE IF EXISTS $SCRATCH WITH (FORCE)"' EXIT

docker exec -i "$CONTAINER" pg_restore -U "$DB_USER" -d "$SCRATCH" --no-owner --exit-on-error < "$FILE"

docker exec "$CONTAINER" psql -U "$DB_USER" -d "$SCRATCH" -Atc "
  SELECT '  users: ' || count(*) FROM users UNION ALL
  SELECT '  projects: ' || count(*) FROM projects UNION ALL
  SELECT '  tasks: ' || count(*) FROM tasks UNION ALL
  SELECT '  plans: ' || count(*) FROM plans UNION ALL
  SELECT '  migrations: ' || count(*) FROM schema_migrations"
echo "Restore OK"
