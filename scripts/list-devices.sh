#!/bin/bash
# List available deploy targets: connected physical devices and available simulators.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_cmd xcrun

echo "# Physical devices (via devicectl)"
xcrun devicectl list devices

echo
echo "# Simulators (available)"
xcrun simctl list devices available
