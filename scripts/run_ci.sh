#!/bin/bash

set -exo pipefail
source scripts/config.sh

if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then
  printf "\e[1;31mError: Unclean git environment.\e[0m\n"
  exit -1
fi

scripts/bootstrap.sh

# Xcode 12 has nicer formatter than swiftformat
# scripts/format.sh
# if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then
#   printf "\e[1;31mError: Found changes after running 'scripts/format.sh'.\e[0m\n"
#   exit -1
# fi

tools/mint run swiftlint --strict

xcrun xcodebuild -version
xcrun xcodebuild -resolvePackageDependencies
xcrun xcodebuild "${XCODEBUILD_ARGS[@]}" -scheme Magnesium test \
  | tools/mint run xcbeautify
