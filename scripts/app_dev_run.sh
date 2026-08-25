#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR/.."

exec flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8102 \
  --no-web-resources-cdn
