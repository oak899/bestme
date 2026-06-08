#!/usr/bin/env bash
cd "$(dirname "$0")/.."
./deploy/deploy.sh 2>&1 | tee deploy/deploy.log
read -r -p "Press Enter to close..."
