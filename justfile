# Magnesium command runner — https://just.systems/man/en/
# First-time setup: ./bootstrap.sh  (installs just + Brewfile tools)

set dotenv-load := false

# List available recipes
default:
    @just --list

# Install (or update) Homebrew-managed dev tools from the Brewfile
install-tools:
    brew bundle --file={{ justfile_directory() }}/Brewfile

# Regenerate Magnesium.xcodeproj from project.yml
generate:
    xcodegen generate --spec {{ justfile_directory() }}/project.yml

# Format Swift sources in place
format:
    swift-format format --in-place Sources/ Tests/ Packages/*/Sources Packages/*/Tests

# Lint (swift-format check + SwiftLint)
lint:
    swift-format lint --recursive Sources Tests Packages/*/Sources Packages/*/Tests
    swiftlint lint --strict

# Manually upload dSYMs under PATH (build phase uploads automatically)
upload-dsyms path:
    {{ justfile_directory() }}/scripts/upload-dsyms.sh {{ path }}
