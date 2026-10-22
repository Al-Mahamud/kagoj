#!/usr/bin/env bash
# Regenerates the README screenshots in docs/screenshots/.
# Needs: Flutter, Google Chrome, Node 22+, Python 3 with Pillow, Noto Sans fonts.
#
# Builds lib/demo/main_demo.dart (real screens, fictional sample content) for
# the web, captures each screen in headless Chrome at 390x844 @3x, then frames
# and captions them.
set -euo pipefail
cd "$(dirname "$0")/../.."

out=$(mktemp -d)
created_web=0
if [ ! -d web ]; then
  flutter create --platforms web . >/dev/null   # Kagoj ships for Android only
  created_web=1
fi

cleanup() {
  [ -n "${server:-}" ] && kill "$server" 2>/dev/null || true
  [ "$created_web" = 1 ] && rm -rf web || true
}
trap cleanup EXIT

flutter build web -t lib/demo/main_demo.dart --release --no-web-resources-cdn -o "$out/web"
python3 -m http.server 8765 --bind 127.0.0.1 --directory "$out/web" >/dev/null 2>&1 &
server=$!
sleep 1

node tool/screenshots/shoot.mjs http://127.0.0.1:8765 "$out/shots"
python3 tool/screenshots/compose.py "$out/shots" .
echo "Screenshots written to docs/screenshots/"
