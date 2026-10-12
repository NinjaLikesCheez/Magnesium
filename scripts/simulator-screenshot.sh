#!/bin/bash
# Capture a screenshot of a booted simulator, for an agent to review a UI change.
#
# Usage:
#   scripts/simulator-screenshot.sh [-d "iPhone 16"] [-o /path/to/out.png]
#
# Prints the output path on success.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DEVICE_NAME="iPhone 17"
OUT_PATH=""

while getopts "d:o:h" opt; do
	case "$opt" in
		d) DEVICE_NAME="$OPTARG" ;;
		o) OUT_PATH="$OPTARG" ;;
		h)
			echo "Usage: $0 [-d \"iPhone 16\"] [-o /path/to/out.png]"
			exit 0
			;;
		*) die "unknown option" ;;
	esac
done

require_cmd xcrun

UDID="$(
	xcrun simctl list devices -j \
		| /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
name = "'"$DEVICE_NAME"'"
for devices in data["devices"].values():
	for d in devices:
		if d["name"] == name and d["state"] == "Booted":
			print(d["udid"])
			sys.exit(0)
'
)"

[ -n "$UDID" ] || die "no booted simulator found matching name '$DEVICE_NAME'. Run scripts/deploy-simulator.sh first."

if [ -z "$OUT_PATH" ]; then
	mkdir -p "$BUILD_DIR/screenshots"
	OUT_PATH="$BUILD_DIR/screenshots/$(date +%Y%m%d-%H%M%S).png"
fi

xcrun simctl io "$UDID" screenshot "$OUT_PATH" >/dev/null

echo "$OUT_PATH"
