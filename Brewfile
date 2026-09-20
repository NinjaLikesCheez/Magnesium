# Development tools for Magnesium.
# First-time setup: ./bootstrap.sh
# Later updates: `just install-tools` (or `brew bundle`)

# Command runner — https://just.systems
brew "just"

# Regenerate Magnesium.xcodeproj from project.yml
brew "xcodegen"

# Formatting / linting (see .swift-format / .swiftlint.yml)
brew "swift-format"
brew "swiftlint"

# Upload dSYMs / debug files to Sentry from Xcode builds.
# `trusted:` is required under Homebrew 6+ tap-trust for non-official taps.
tap "getsentry/tools"
brew "getsentry/tools/sentry-cli", trusted: true
