#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:54329/iris}"
export DATABASE_URL

for attempt in $(seq 1 60); do
  if pg_isready -d "$DATABASE_URL" >/dev/null 2>&1; then
    echo "Database is ready"
    exit 0
  fi
  sleep 1
done

echo "Database did not become ready" >&2
exit 1
