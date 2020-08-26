#!/bin/bash

set -exo pipefail
source scripts/config.sh

find Tests -type d -name __Snapshots__  | xargs rm -rf

xcodebuild "${XCODEBUILD_ARGS[@]}" -scheme Magnesium test \
  | tools/mint run xcbeautify
