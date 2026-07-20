#!/bin/bash
# Stream Magnesium's console output from a booted simulator.
#
# Usage:
#   scripts/simulator-logs.sh [-d "iPhone 16"]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DEVICE_NAME="iPhone 17"

while getopts "d:h" opt; do
	case "$opt" in
		d) DEVICE_NAME="$OPTARG" ;;
		h)
			echo "Usage: $0 [-d \"iPhone 16\"]"
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

log "Streaming logs for $BUNDLE_ID on $DEVICE_NAME ($UDID) (Ctrl-C to stop)..."
xcrun simctl spawn "$UDID" log stream --level debug --predicate "subsystem == \"$BUNDLE_ID\" OR process == \"Magnesium\""
