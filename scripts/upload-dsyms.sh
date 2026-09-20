#!/bin/bash
# Upload dSYMs / debug information files to Sentry.
#
# Used as an Xcode post-build Run Script (via project.yml) and by
# `just upload-dsyms <path>`. Requires sentry-cli (`just install-tools`) and a
# Sentry auth token via SENTRY_AUTH_TOKEN or `[auth] token=...` in
# ~/.sentryclirc / .sentryclirc. Org/project defaults live in .sentryclirc.

set -euo pipefail

if [[ "$(uname -m)" == arm64 ]]; then
	export PATH="/opt/homebrew/bin:$PATH"
fi

# Allow calling with an explicit path (manual / just) or Xcode's dSYM folder.
DSYM_PATH="${1:-${DWARF_DSYM_FOLDER_PATH:-}}"

if [[ -z "${DSYM_PATH}" ]]; then
	echo "warning: sentry-cli - no dSYM path provided (pass an argument or set DWARF_DSYM_FOLDER_PATH); skipping upload"
	exit 0
fi

if [[ ! -e "${DSYM_PATH}" ]]; then
	echo "warning: sentry-cli - dSYM path does not exist yet (${DSYM_PATH}); skipping upload"
	exit 0
fi

if ! command -v sentry-cli >/dev/null 2>&1; then
	echo "warning: sentry-cli not installed — run \`just install-tools\` (see Brewfile)"
	exit 0
fi

# Resolve repo root when run from Xcode (SRCROOT) or from just/scripts.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SRCROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
cd "${REPO_ROOT}"

# Prefer env overrides; otherwise sentry-cli reads .sentryclirc [defaults].
export SENTRY_ORG="${SENTRY_ORG:-ninjalikescheez}"
export SENTRY_PROJECT="${SENTRY_PROJECT:-magnesium}"

has_sentry_token() {
	if [[ -n "${SENTRY_AUTH_TOKEN:-}" ]]; then
		return 0
	fi
	local config
	for config in "${HOME}/.sentryclirc" "${REPO_ROOT}/.sentryclirc"; do
		[[ -f "${config}" ]] || continue
		if grep -Eq '^[[:space:]]*token[[:space:]]*=' "${config}"; then
			return 0
		fi
	done
	return 1
}

if ! has_sentry_token; then
	echo "warning: sentry-cli - not authenticated (set SENTRY_AUTH_TOKEN or add token= to ~/.sentryclirc); skipping dSYM upload"
	exit 0
fi

echo "Uploading dSYMs from ${DSYM_PATH} to Sentry (${SENTRY_ORG}/${SENTRY_PROJECT})..."

# --include-sources enables Source Context next to stack frames in Sentry.
# Soft-fail with a warning so local Debug builds aren't blocked offline.
if ! ERROR="$(sentry-cli debug-files upload --include-sources "${DSYM_PATH}" 2>&1)"; then
	echo "warning: sentry-cli - ${ERROR}"
	exit 0
fi

echo "sentry-cli: dSYM upload finished"
