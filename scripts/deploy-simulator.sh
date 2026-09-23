#!/bin/bash
# Build Magnesium and install/launch it on an iOS Simulator.
#
# Usage:
#   scripts/deploy-simulator.sh [-d "iPhone 16"] [-o ios26]
#
# Boots the named simulator if needed, builds for it, installs the .app,
# launches it, and opens Simulator.app so a screenshot can be taken.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DEVICE_NAME="iPhone 17"
OS_VERSION=""

while getopts "d:o:h" opt; do
	case "$opt" in
		d) DEVICE_NAME="$OPTARG" ;;
		o) OS_VERSION="$OPTARG" ;;
		h)
			echo "Usage: $0 [-d \"iPhone 16\"] [-o 26.0]"
			exit 0
			;;
		*) die "unknown option" ;;
	esac
done

require_cmd xcodebuild
require_cmd xcrun
require_project

if [ -n "$OS_VERSION" ]; then
	DESTINATION="platform=iOS Simulator,name=$DEVICE_NAME,OS=$OS_VERSION"
else
	DESTINATION="platform=iOS Simulator,name=$DEVICE_NAME"
fi

log "Looking up simulator matching: $DEVICE_NAME ${OS_VERSION:+(OS=$OS_VERSION)}"
UDID="$(
	xcrun simctl list devices available -j \
		| /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
name = "'"$DEVICE_NAME"'"
os_version = "'"$OS_VERSION"'"
for runtime, devices in data["devices"].items():
	if os_version and os_version not in runtime:
		continue
	for d in devices:
		if d["name"] == name and d["isAvailable"]:
			print(d["udid"])
			sys.exit(0)
'
)"

[ -n "$UDID" ] || die "no available simulator found matching name '$DEVICE_NAME' ${OS_VERSION:+os '$OS_VERSION'}"
log "Using simulator $DEVICE_NAME ($UDID)"

BOOT_STATE="$(xcrun simctl list devices -j | /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
udid = "'"$UDID"'"
for devices in data["devices"].values():
	for d in devices:
		if d["udid"] == udid:
			print(d["state"])
			sys.exit(0)
')"

if [ "$BOOT_STATE" != "Booted" ]; then
	log "Booting simulator..."
	xcrun simctl boot "$UDID"
fi

log "Opening Simulator.app"
open -a Simulator --args -CurrentDeviceUDID "$UDID"

log "Building $SCHEME for simulator..."
mkdir -p "$BUILD_DIR"
xcodebuild build \
	-project "$PROJECT_PATH" \
	-scheme "$SCHEME" \
	-destination "$DESTINATION" \
	-derivedDataPath "$BUILD_DIR/DerivedData-Simulator" \
	-skipMacroValidation \
	-skipPackagePluginValidation \
	-quiet

APP_PATH="$(find "$BUILD_DIR/DerivedData-Simulator/Build/Products" -maxdepth 2 -name "Magnesium.app" -path "*iphonesimulator*" | head -1)"
[ -n "$APP_PATH" ] || die "build succeeded but Magnesium.app not found under DerivedData"

log "Installing $APP_PATH"
xcrun simctl install "$UDID" "$APP_PATH"

log "Launching $BUNDLE_ID"
xcrun simctl launch "$UDID" "$BUNDLE_ID"

log "Deployed to simulator $DEVICE_NAME ($UDID)"
