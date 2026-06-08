#!/usr/bin/env bash
# Quick upload when ./deploy/deploy.sh already built artifacts locally.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${DEPLOY_HOST:-45.76.66.28}"
USER="${DEPLOY_USER:-root}"
REMOTE_DIR="/opt/bestme"

test -f "$ROOT/deploy/artifacts/bestme" || { echo "Run: cd api && GOOS=linux GOARCH=amd64 go build -o ../deploy/artifacts/bestme ./cmd/server"; exit 1; }

echo "==> Stopping bestme, uploading binary + web"
ssh "$USER@$HOST" "systemctl stop bestme"
scp "$ROOT/deploy/artifacts/bestme" "$USER@$HOST:$REMOTE_DIR/bin/bestme.new"
ssh "$USER@$HOST" "mv $REMOTE_DIR/bin/bestme.new $REMOTE_DIR/bin/bestme && chmod +x $REMOTE_DIR/bin/bestme"
if [[ -f "$ROOT/app/build/web/index.html" ]]; then
  rsync -az --delete "$ROOT/app/build/web/" "$USER@$HOST:$REMOTE_DIR/web/"
fi
ssh "$USER@$HOST" "systemctl start bestme && sleep 1 && curl -s http://127.0.0.1:8090/api"
echo ""
echo "==> Done. Verify: curl -s https://bestme.zfloo.com/api/kanban | head"
