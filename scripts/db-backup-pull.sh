#!/usr/bin/env bash
# Copies the server's backups to this machine (off-site copy: a dead server must not take the backups with it).
# Only new files are transferred. Usage: ./scripts/db-backup-pull.sh user@server /path/to/planner/on/server [local-dir]
set -euo pipefail

TARGET="${1:?Usage: $0 user@server /path/to/planner [local-dir]}"
REMOTE_DIR="${2:?Usage: $0 user@server /path/to/planner [local-dir]}"
LOCAL_DIR="${3:-$HOME/onelineplanner-backups}"

mkdir -p "$LOCAL_DIR"
rsync -av --ignore-existing "$TARGET:$REMOTE_DIR/backups/" "$LOCAL_DIR/"
echo "Backups in $LOCAL_DIR:"
ls -1t "$LOCAL_DIR" | head -n 5
