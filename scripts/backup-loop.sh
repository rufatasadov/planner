#!/bin/sh
# Entry point of the "backup" compose service: a full pg_dump (schema + data, custom format)
# right away and then every BACKUP_INTERVAL_HOURS; dumps older than BACKUP_KEEP_DAYS are deleted.
# Restore check: ./scripts/db-restore-test.sh
set -eu

INTERVAL=$(( ${BACKUP_INTERVAL_HOURS:-24} * 3600 ))
KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
mkdir -p /backups

until pg_isready -h db -U "$PGUSER" -d "$PGDATABASE" -q; do sleep 2; done

while true; do
  file="/backups/planner-$(date +%Y%m%d-%H%M%S).dump"
  if pg_dump -h db -U "$PGUSER" -d "$PGDATABASE" -Fc -f "$file.tmp"; then
    mv "$file.tmp" "$file"
    echo "$(date -Iseconds) backup ok: $file ($(du -h "$file" | cut -f1))"
  else
    rm -f "$file.tmp"
    echo "$(date -Iseconds) backup FAILED" >&2
  fi
  find /backups -name 'planner-*.dump' -mtime +"$KEEP_DAYS" -delete
  sleep "$INTERVAL"
done
