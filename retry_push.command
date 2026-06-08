#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
git branch -M main
git push -u origin main
echo "Pushed to https://github.com/oak899/bestme"
read -r -p "Press Enter to close..."
