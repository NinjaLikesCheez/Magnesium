#!/bin/bash

set -exo pipefail
source scripts/config.sh

if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then
  printf "\e[1;31mError: Unclean git environment.\e[0m\n"
  exit -1
fi

scripts/bootstrap.sh

scripts/format.sh
if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then
  printf "\e[1;31mError: Found changes after running 'scripts/format.sh'.\e[0m\n"
  exit -1
fi

tools/mint run swiftlint --strict

if [ -n "$(scripts/LocalizationLint.swift)" ]; then
  printf "\e[1;31mError: Found localization issues.\e[0m\n"
  exit -1
fi

xcrun xcodebuild -version
xcrun xcodebuild "${XCODEBUILD_ARGS[@]}" -derivedDataPath build -scheme Magnesium clean build test \
  | tools/mint run xcbeautify

bundle exec slather
