#!/usr/bin/env bash
# Cut a release: tag the current info.json version and push the tag, which
# triggers .github/workflows/release.yml to build the zip and publish the
# GitHub Release.
#
# Flow:
#   1. Bump the version + write the changelog (e.g. `npm run version`, then edit
#      changelog.txt), commit, and push to main.
#   2. Run `npm run release` (this script).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SRC"

VERSION="$(node -p "require('./info.json').version")"
TAG="v$VERSION"

if ! grep -q "^Version: ${VERSION}$" changelog.txt; then
    echo "changelog.txt has no 'Version: ${VERSION}' section — add release notes first." >&2
    exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree has uncommitted changes — commit and push them first." >&2
    exit 1
fi

if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
    echo "Tag ${TAG} already exists." >&2
    exit 1
fi

git tag "$TAG"
git push origin "$TAG"
echo "Pushed ${TAG}. GitHub Actions will build and publish the release:"
echo "  https://github.com/jhgaylor/factorio-must-fall/releases"
