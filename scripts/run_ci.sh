#!/bin/bash

set -exo pipefail
source scripts/config.sh

if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then
  printf "\e[1;31mError: Unclean git environment.\e[0m\n"
  exit -1
fi

scripts/bootstrap.sh

tools/mint run swiftlint --strict

xcrun xcodebuild -version
xcrun xcodebuild -resolvePackageDependencies
xcrun xcodebuild "${XCODEBUILD_ARGS[@]}" -scheme Magnesium clean build test \
  | tools/mint run xcbeautify
