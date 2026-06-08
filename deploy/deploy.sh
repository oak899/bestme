#!/usr/bin/env bash
set -euo pipefail

# Deploy BestMe to 45.76.66.28 without touching other projects (vivid, iwell, reson, livekit).
# Usage: ./deploy/deploy.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${DEPLOY_HOST:-45.76.66.28}"
USER="${DEPLOY_USER:-root}"
REMOTE_DIR="/opt/bestme"
ARTIFACTS="$ROOT/deploy/artifacts"

mkdir -p "$ARTIFACTS"

echo "==> Building Go binary (linux/amd64)"
cd "$ROOT/api"
GOOS=linux GOARCH=amd64 go build -o "$ARTIFACTS/bestme" ./cmd/server

echo "==> Building Flutter web (optional)"
WEB_BUILT=0
if command -v flutter >/dev/null 2>&1; then
  cd "$ROOT/app"
  flutter pub get >/dev/null 2>&1 || true
  if flutter build web --release \
      --dart-define=API_BASE_URL=https://bestme.zfloo.com/api 2>/dev/null; then
    WEB_BUILT=1
  else
    echo "    (flutter web build skipped — run manually or use mobile app)"
  fi
else
  echo "    (flutter not found — skipping web build)"
fi

echo "==> Preparing remote directory $REMOTE_DIR"
ssh "$USER@$HOST" "mkdir -p $REMOTE_DIR/{bin,web,data} && systemctl stop bestme 2>/dev/null || true"

echo "==> Uploading binary and configs"
scp "$ARTIFACTS/bestme" "$USER@$HOST:$REMOTE_DIR/bin/bestme.new"
ssh "$USER@$HOST" "mv $REMOTE_DIR/bin/bestme.new $REMOTE_DIR/bin/bestme && chmod +x $REMOTE_DIR/bin/bestme"
scp "$ROOT/deploy/bestme.service" "$USER@$HOST:/etc/systemd/system/bestme.service"
# Keep existing nginx + TLS on server if already configured
if ! ssh "$USER@$HOST" "test -f /etc/letsencrypt/live/bestme.zfloo.com/fullchain.pem"; then
  scp "$ROOT/deploy/nginx.conf" "$USER@$HOST:/etc/nginx/sites-available/bestme"
fi

if [[ "$WEB_BUILT" -eq 1 ]]; then
  rsync -az --delete "$ROOT/app/build/web/" "$USER@$HOST:$REMOTE_DIR/web/"
else
  ssh "$USER@$HOST" "test -f $REMOTE_DIR/web/index.html" 2>/dev/null || \
    ssh "$USER@$HOST" "printf '%s\n' '<!DOCTYPE html><html><body><h1>BestMe API</h1><p>Use the Flutter mobile app or rebuild web.</p><p><a href=\"/api\">/api</a></p></body></html>' > $REMOTE_DIR/web/index.html"
fi

echo "==> Enabling services (bestme only)"
ssh "$USER@$HOST" bash -s <<'REMOTE'
set -e
chmod +x /opt/bestme/bin/bestme
ln -sf /etc/nginx/sites-available/bestme /etc/nginx/sites-enabled/bestme
# Do NOT remove or replace vivid default_server or other site configs.
nginx -t
systemctl daemon-reload
systemctl enable bestme
systemctl restart bestme
systemctl reload nginx
systemctl status bestme --no-pager | head -6
REMOTE

if ! ssh "$USER@$HOST" "test -f $REMOTE_DIR/bestme.env"; then
  echo ""
  echo "==> IMPORTANT: Create $REMOTE_DIR/bestme.env with OPENAI_API_KEY"
  echo "    ssh $USER@$HOST 'cp $REMOTE_DIR/bestme.env.example $REMOTE_DIR/bestme.env && chmod 600 $REMOTE_DIR/bestme.env && nano $REMOTE_DIR/bestme.env'"
  scp "$ROOT/deploy/bestme.env.example" "$USER@$HOST:$REMOTE_DIR/bestme.env.example" 2>/dev/null || true
fi

echo ""
echo "==> Deploy complete"
echo "    API (local):  http://127.0.0.1:8090/api  (on server)"
echo "    Public:       https://bestme.zfloo.com/"
echo "    Flutter app:  --dart-define=API_BASE_URL=https://bestme.zfloo.com/api"
echo ""
echo "    Other projects untouched: vivid (:8088), iwell (:9999), reson, livekit"
