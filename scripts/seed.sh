#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:54329/iris}"
export DATABASE_URL

psql "$DATABASE_URL" --set ON_ERROR_STOP=1 -f seed/seed.sql
psql "$DATABASE_URL" --set ON_ERROR_STOP=1 -f seed/seed_staging.sql

echo "Deterministic fixtures loaded."
