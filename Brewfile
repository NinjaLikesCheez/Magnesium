# Development tools for Magnesium.
# Install with: `just install-tools`  (or `brew bundle`)

# Command runner — https://just.systems
brew "just"

# Regenerate Magnesium.xcodeproj from project.yml
brew "xcodegen"

# Formatting / linting (see .swift-format / .swiftlint.yml)
brew "swift-format"
brew "swiftlint"

# Upload dSYMs / debug files to Sentry from Xcode builds
tap "getsentry/tools"
brew "getsentry/tools/sentry-cli"
