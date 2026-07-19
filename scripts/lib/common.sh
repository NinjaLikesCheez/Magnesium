#!/bin/bash
# Shared helpers for scripts/*.sh. Source this, don't execute it directly.

set -euo pipefail

SCRIPTS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_LIB_DIR/../.." && pwd)"

PROJECT_PATH="$REPO_ROOT/Magnesium.xcodeproj"
SCHEME="Magnesium"
BUNDLE_ID="bykim.cracks.Magnesium"
BUILD_DIR="$REPO_ROOT/build"

log() { echo "==> $*" >&2; }
die() { echo "error: $*" >&2; exit 1; }

require_project() {
	if [ ! -d "$PROJECT_PATH" ]; then
		log "Magnesium.xcodeproj not found — running xcodegen generate"
		(cd "$REPO_ROOT" && xcodegen generate --spec project.yml)
	fi
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not found on PATH"
}

# Resolves a device name/udid (or, if empty, the first connected device) to a
# UDID via devicectl. Name-based xcodebuild/devicectl destinations can be
# ambiguous when devicectl reports stale duplicate entries for a device name,
# so scripts should target the UDID this prints rather than a name.
resolve_device_udid() {
	local query="${1:-}"
	xcrun devicectl list devices -j - 2>/dev/null \
		| DEVICE_QUERY="$query" /usr/bin/python3 -c '
import json, os, sys
data = json.load(sys.stdin)
query = os.environ.get("DEVICE_QUERY", "")
devices = data["result"]["devices"]

def connected(d):
	return d["connectionProperties"]["tunnelState"] == "connected"

if query:
	candidates = [d for d in devices if query in (d["deviceProperties"]["name"], d["hardwareProperties"]["udid"])]
else:
	candidates = devices

connected_candidates = [d for d in candidates if connected(d)]
chosen = connected_candidates[0] if connected_candidates else None

if chosen:
	print(chosen["hardwareProperties"]["udid"])
'
}
