#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:54329/iris}"
export DATABASE_URL

psql "$DATABASE_URL" --set ON_ERROR_STOP=1 -f queries/verify_schema.sql
psql "$DATABASE_URL" --set ON_ERROR_STOP=1 -f queries/verify_spatial_roundtrip.sql
psql "$DATABASE_URL" --set ON_ERROR_STOP=1 -f queries/verify_index_usage.sql
psql "$DATABASE_URL" --set ON_ERROR_STOP=1 -f tests/test_schema.sql

echo "All SQL verification checks passed."
