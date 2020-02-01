#!/bin/bash

set -e
export FASTLANE_SKIP_UPDATE_CHECK=1

if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then 
  printf "\e[1;31mError: Unclean git environment.\e[0m\n"
  exit -1
fi

bundle install

scripts/format.sh
if [ -n "$(git ls-files --others --modified --exclude-standard)" ]; then 
  printf "\e[1;31mErrpr: Found changes after running 'scripts/format.sh'.\e[0m\n"
  exit -1
fi

bundle exec fastlane test
bundle exec fastlane build
