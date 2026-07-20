#!/bin/bash
# Launch (or relaunch) Magnesium on a physical device with its console attached
# via devicectl, streaming stdout/stderr until interrupted (Ctrl-C) or exit.
# For simulators, use scripts/simulator-logs.sh instead.
#
# Usage:
#   scripts/device-logs.sh [-d "Thomas's iPhone"]
#
# Note: --console causes devicectl to (re)launch the app itself, terminating
# any existing instance first — this is not a passive attach to a running app.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DEVICE_QUERY=""

while getopts "d:h" opt; do
	case "$opt" in
		d) DEVICE_QUERY="$OPTARG" ;;
		h)
			echo "Usage: $0 [-d <device name|udid>]"
			exit 0
			;;
		*) die "unknown option" ;;
	esac
done

require_cmd xcrun

UDID="$(resolve_device_udid "$DEVICE_QUERY")"
if [ -z "$UDID" ]; then
	if [ -n "$DEVICE_QUERY" ]; then
		die "no connected device found matching '$DEVICE_QUERY'. Run scripts/list-devices.sh to see options."
	else
		die "no connected device found. Plug in / unlock a device, or pass -d <name|udid>."
	fi
fi

log "Launching $BUNDLE_ID with console attached on $UDID (Ctrl-C to stop)..."
xcrun devicectl device process launch \
	--device "$UDID" \
	--terminate-existing \
	--console \
	"$BUNDLE_ID"
