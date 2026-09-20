#!/bin/bash
# Bootstrap local Magnesium tooling: install `just`, then Brewfile deps via
# `just install-tools`. Safe to re-run.
#
# Usage: ./bootstrap.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

if [[ "$(uname -s)" != Darwin ]]; then
	echo "error: bootstrap.sh expects macOS with Homebrew (found $(uname -s))" >&2
	exit 1
fi

if [[ "$(uname -m)" == arm64 ]]; then
	export PATH="/opt/homebrew/bin:$PATH"
fi

if ! command -v brew >/dev/null 2>&1; then
	echo "error: Homebrew is required — install from https://brew.sh then re-run ./bootstrap.sh" >&2
	exit 1
fi

if ! command -v just >/dev/null 2>&1; then
	echo "Installing just..."
	brew install just
else
	echo "just already installed: $(command -v just)"
fi

echo "Installing Brewfile tools..."
just install-tools

echo "Bootstrap complete. Useful next steps:"
echo "  just generate          # regenerate Magnesium.xcodeproj"
echo "  just --list            # see all recipes"
echo "  export SENTRY_AUTH_TOKEN=…   # enable dSYM uploads (see AGENTS.md)"
