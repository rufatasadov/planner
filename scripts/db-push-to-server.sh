#!/usr/bin/env bash
# Exports the local database and imports it on the server over SSH in one step.
# Usage: ./scripts/db-push-to-server.sh user@server /path/to/planner/on/server
set -euo pipefail

TARGET="${1:?Usage: $0 user@server /path/to/planner}"
REMOTE_DIR="${2:?Usage: $0 user@server /path/to/planner}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILE="planner-data-$(date +%Y%m%d-%H%M%S).sql"

"$SCRIPT_DIR/db-export.sh" "/tmp/$FILE"
scp "/tmp/$FILE" "$TARGET:/tmp/$FILE"
scp "$SCRIPT_DIR/db-import.sh" "$TARGET:/tmp/planner-db-import.sh"
ssh -t "$TARGET" "cd '$REMOTE_DIR' && bash /tmp/planner-db-import.sh '/tmp/$FILE'; rm -f '/tmp/$FILE' /tmp/planner-db-import.sh"
rm -f "/tmp/$FILE"
