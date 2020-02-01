bundle config set deployment 'true'
bundle install

scripts/format.sh
git diff --exit-code
if [ $? -ne 0 ]; then 
    echo "Found changes after running 'scripts/format.sh'."
  exit -1
fi

bundle exec fastlane test
