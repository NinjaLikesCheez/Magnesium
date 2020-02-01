#!/bin/bash

git diff --exit-code > /dev/null
if [ $? -ne 0 ]; then 
  printf "\e[1;31mUnclean git environment.\e[0m\n"
  exit -1
fi

bundle install

scripts/format.sh
git diff --exit-code
if [ $? -ne 0 ]; then 
  printf "\e[1;31mFound changes after running 'scripts/format.sh'.\e[0m\n"
  exit -1
fi

bundle exec fastlane test
