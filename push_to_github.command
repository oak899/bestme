#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "=== Initializing git ==="
git init 2>/dev/null || true
git add -A

if git diff --cached --quiet; then
  echo "Nothing to commit"
else
  git commit -m "$(cat <<'EOF'
Initial BestMe app: Flutter + Go API for Vercel.

AI-powered daily tracking for life, work, and exercise with routines,
verification tasks, summaries, and event reminders via MongoDB Atlas.
EOF
)"
fi

GH="${GH_BIN:-$HOME/.local/bin/gh}"
REMOTE="git@github.com:oak899/growthos.git"

if git remote | grep -qx origin; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi

if "$GH" repo view oak899/growthos >/dev/null 2>&1; then
  echo "Repo exists, pushing..."
else
  echo "Creating repo oak899/growthos..."
  "$GH" repo create oak899/growthos --public --source=. --remote=origin --push
  echo "Done: https://github.com/oak899/growthos"
  read -r -p "Press Enter to close..."
  exit 0
fi

git branch -M main
git push -u origin main
echo "Done: https://github.com/oak899/growthos"
read -r -p "Press Enter to close..."
