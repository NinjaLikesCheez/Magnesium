#!/bin/bash

echo "Testing Swift Testing framework setup..."

# Try to build the test target
echo "Building test target..."
xcodebuild build -project Magnesium.xcodeproj -scheme MagnesiumTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet

if [ $? -eq 0 ]; then
    echo "✅ Test target builds successfully"
    
    # Try to run the tests
    echo "Running tests..."
    xcodebuild test -project Magnesium.xcodeproj -scheme MagnesiumTests -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
    
    if [ $? -eq 0 ]; then
        echo "✅ Tests run successfully"
    else
        echo "❌ Tests failed to run"
    fi
else
    echo "❌ Test target failed to build"
fi