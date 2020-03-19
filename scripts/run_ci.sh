#!/bin/bash

set -ex
export FASTLANE_SKIP_UPDATE_CHECK=1

if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then
  printf "\e[1;31mError: Unclean git environment.\e[0m\n"
  exit -1
fi

scripts/format.sh
if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then
  printf "\e[1;31mError: Found changes after running 'scripts/format.sh'.\e[0m\n"
  exit -1
fi

scripts/swiftlint.sh --strict

bundle install
bundle exec fastlane run_ci
