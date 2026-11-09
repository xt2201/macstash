#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Running MacStash & SideDock automated test suite..."
swift run MacStashTestRunner

echo "==> All test suites passed."
