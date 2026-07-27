#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Building the Ubuntu test image..."
docker compose build ubuntu-bootstrap-test

echo "Running the complete Linux bootstrap and repository checks in a clean container..."
docker compose run --rm -T ubuntu-bootstrap-test

echo "Docker bootstrap test passed."
