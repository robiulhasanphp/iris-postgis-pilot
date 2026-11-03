#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:54329/iris}"
export DATABASE_URL

for file in migrations/*.sql; do
  echo "Applying ${file}"
  psql "${DATABASE_URL}" --set ON_ERROR_STOP=1 -f "${file}"
done

echo "Database schema ready"
