#!/usr/bin/env bash
set -euo pipefail

rm -rf dist && mkdir -p dist/fonts
cp index.html dist/
cp fonts/*.woff2 fonts/*.woff dist/fonts/
echo "built dist/"