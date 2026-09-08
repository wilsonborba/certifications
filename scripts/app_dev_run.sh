#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR/.."

# Calculate current Bangkok time (+07) automatically
BKK_TIMESTAMP=$(TZ="Asia/Bangkok" date +"%Y-%m-%d %H:%M +07")

exec flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8102 \
  --dart-define=DEVELOPMENT_MODE=true \
  --dart-define=BUILD_TIMESTAMP="$BKK_TIMESTAMP"
