#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:54329/iris}"
export DATABASE_URL

psql "${DATABASE_URL}" --set ON_ERROR_STOP=1 <<'SQL'
DROP SCHEMA IF EXISTS iris_core CASCADE;
DROP SCHEMA IF EXISTS iris_staging CASCADE;
SQL

./scripts/migrate.sh
./scripts/seed.sh
