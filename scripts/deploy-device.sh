#!/bin/bash
# Build Magnesium and install/launch it on a physical device via devicectl.
#
# Usage:
#   scripts/deploy-device.sh [-d "Thomas's iPhone"]
#
# Requires automatic signing to already be configured (config/Signing.xcconfig,
# see config/Signing.xcconfig.template) and the device to be paired/trusted.
# Run scripts/list-devices.sh to see available device names/identifiers.

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

require_cmd xcodebuild
require_cmd xcrun
require_project

[ -f "$REPO_ROOT/config/Signing.xcconfig" ] || die \
	"config/Signing.xcconfig not found. Copy config/Signing.xcconfig.template and fill in your team/bundle id first."

UDID="$(resolve_device_udid "$DEVICE_QUERY")"

if [ -z "$UDID" ]; then
	if [ -n "$DEVICE_QUERY" ]; then
		die "no connected device found matching '$DEVICE_QUERY'. Run scripts/list-devices.sh to see options."
	else
		die "no connected device found. Plug in / unlock a device, or pass -d <name|udid>."
	fi
fi

log "Target device UDID: $UDID"

DESTINATION="platform=iOS,id=$UDID"

log "Building $SCHEME for device (automatic signing)..."
mkdir -p "$BUILD_DIR"
xcodebuild build \
	-project "$PROJECT_PATH" \
	-scheme "$SCHEME" \
	-destination "$DESTINATION" \
	-derivedDataPath "$BUILD_DIR/DerivedData-Device" \
	-allowProvisioningUpdates \
	-skipMacroValidation \
	-skipPackagePluginValidation \
	-quiet

APP_PATH="$(find "$BUILD_DIR/DerivedData-Device/Build/Products" -maxdepth 2 -name "Magnesium.app" -path "*iphoneos*" | head -1)"
[ -n "$APP_PATH" ] || die "build succeeded but Magnesium.app not found under DerivedData"

log "Installing $APP_PATH on $UDID"
xcrun devicectl device install app --device "$UDID" "$APP_PATH" \
	|| die "install failed — not launching, since the device would just relaunch whatever build is already installed. See the devicectl error above (a wireless-only connection commonly can't install; try USB)."

log "Launching $BUNDLE_ID on $UDID"
xcrun devicectl device process launch --device "$UDID" --terminate-existing "$BUNDLE_ID"

log "Deployed to device: $UDID"
log "Tip: run scripts/device-logs.sh -d \"$UDID\" to stream logs."
