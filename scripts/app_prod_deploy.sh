#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Calculate current Bangkok time (+07) automatically
BKK_TIMESTAMP=$(TZ="Asia/Bangkok" date +"%Y-%m-%d %H:%M +07")

echo "=== Building Certifications Web (Timestamp: $BKK_TIMESTAMP) ==="
cd "$REPO_DIR"

flutter build web \
  --release \
  --no-tree-shake-icons \
  --dart-define=BUILD_TIMESTAMP="$BKK_TIMESTAMP"

echo "=== Deploying to Cloudflare Pages (certifications.asodya.com) ==="
python3 -c "
import sys, os
from pathlib import Path

# Import deployment logic
sys.path.insert(0, '$SCRIPT_DIR')
from cloudflare_deployer import deploy_pages_project

deploy_pages_project(
    project_name='asodya-certifications',
    build_dir='$REPO_DIR/build/web',
    custom_domain='certifications.asodya.com',
    branch='main',
    timestamp_str='$BKK_TIMESTAMP'
)
"
