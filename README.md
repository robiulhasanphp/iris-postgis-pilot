# IRIS PostGIS Pilot

A small, reproducible PostgreSQL/PostGIS implementation for the IRIS pilot.

The project focuses on a clear database contract for geospatial data, including source lineage, country-scoped identifiers, spatial constraints and indexes, and deterministic local fixtures for verification.

This is a **pilot implementation**, not a production data platform. The data in `seed/seed.sql` is synthetic and intended only for local testing.

## What this project does

The database is split into two schemas:

- `iris_staging` — a simple landing area for source-shaped records.
- `iris_core` — the controlled schema used by the application and spatial queries.

The core schema contains:

- `source_run` — records where a dataset came from and when it was loaded.
- `parcel` — candidate land parcels.
- `substation` — grid substations.
- `peatland` — peatland/environmental areas.
- `screening_layer` — other spatial screening areas.
- `evidence` — supporting information linked to a core entity.

The design keeps source information with the data so results can be traced back to their source run and source identifier.

## Technology

- PostgreSQL 16
- PostGIS 3.4
- Docker Compose
- SQL migrations
- Python 3.12+ for the optional test suite
- `psycopg` 3 for Python database checks

## Repository structure

```text
iris-postgis-pilot/
├── README.md
├── docker-compose.yml
├── pyproject.toml
├── .gitignore
├── migrations/
│   ├── 001_extensions_and_schemas.sql
│   ├── 002_staging.sql
│   ├── 003_source_run.sql
│   ├── 004_parcel.sql
│   ├── 005_substation.sql
│   ├── 006_peatland.sql
│   ├── 007_screening_layer.sql
│   └── 008_evidence.sql
├── seed/
│   └── seed.sql
├── queries/
│   ├── verify_schema.sql
│   ├── verify_spatial_roundtrip.sql
│   └── verify_index_usage.sql
├── scripts/
│   ├── migrate.sh
│   ├── reset_db.sh
│   ├── seed.sh
│   ├── verify.sh
│   └── wait_for_db.sh
└── tests/
    ├── test_schema.sql
    └── test_python.py
```

## Running locally with Docker

### Prerequisites

You need Docker Desktop. On Windows, Docker Desktop should be configured to use its WSL 2 engine.

Start the project from the repository directory:

```bash
docker compose up -d
```

Check the database:

```bash
docker compose ps
```

The database service should report `healthy`.

The supplied Compose configuration exposes PostgreSQL on port `54329`:

```text
Database: iris
User: postgres
Password: postgres
Host: localhost
Port: 54329
```

The corresponding local connection string is:

```text
postgresql://postgres:postgres@localhost:54329/iris
```

These credentials are for the local development container only.

## Build the database

The files in `migrations/` are the source of truth for the database schema.

On Linux, macOS, or WSL:

```bash
./scripts/wait_for_db.sh
./scripts/migrate.sh
```

On Windows PowerShell, the SQL files can be applied directly:

```powershell
Get-ChildItem .\migrations\*.sql |
    Sort-Object Name |
    ForEach-Object {
        Write-Host "Running $($_.Name)..."
        Get-Content $_.FullName |
            docker compose exec -T db psql -U postgres -d iris
    }
```

The migrations create PostGIS, the staging/core schemas, tables, constraints, foreign keys, and indexes.

## Load the local fixtures

The fixture data is intentionally small and deterministic. It creates GB test data for parcels, substations, peatland, screening, source lineage, and evidence.

On Windows PowerShell:

```powershell
Get-Content .\seed\seed.sql |
    docker compose exec -T db psql -U postgres -d iris
```

On Linux/macOS/WSL:

```bash
./scripts/seed.sh
```

The seed uses `ON CONFLICT DO NOTHING`, so it can be run again without creating duplicate country/source records.

## Verify the database

The repository contains checks for the schema, spatial relationships, and index usage.

Run the complete verification script in Linux/macOS/WSL:

```bash
./scripts/verify.sh
```

Individual checks:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f queries/verify_schema.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f queries/verify_spatial_roundtrip.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f queries/verify_index_usage.sql
```

The SQL tests are in:

```text
tests/test_schema.sql
```

The optional Python tests can be run with:

```bash
python -m pip install -e '.[test]'
pytest
```

## Windows / PowerShell checks

Check PostgreSQL and PostGIS:

```powershell
docker compose exec db psql -U postgres -d iris -c "SELECT version(); SELECT PostGIS_Version();"
```

List the core tables:

```powershell
docker compose exec db psql -U postgres -d iris -c "\dt iris_core.*"
```

Check fixture counts:

```powershell
docker compose exec db psql -U postgres -d iris -c "SELECT country_code, COUNT(*) FROM iris_core.parcel GROUP BY country_code;"
```

A fresh fixture load should contain two GB parcels.

## Data model

### Country-scoped identifiers

Core business records contain a two-letter uppercase `country_code`.

Source identifiers are unique within a country:

```sql
UNIQUE (country_code, source_id)
```

Foreign keys also include `country_code`. This prevents a record from one country accidentally resolving to an entity from another country.

### Source lineage

Core records retain:

- `source_run_id`
- `source_id`
- `source_date`

`source_run` describes the source extraction/load that produced the record.

### Geometry

Spatial columns are named `geom`.

| Table | Geometry | SRID |
|---|---|---:|
| `parcel` | MultiPolygon | 4326 |
| `substation` | Point | 4326 |
| `peatland` | MultiPolygon | 4326 |
| `screening_layer` | MultiPolygon | 4326 |

The database uses PostGIS geometry typmods to enforce the expected geometry type and SRID.

Source data should be transformed explicitly into EPSG:4326 before promotion into the core schema. The database does not guess a missing CRS.

### Distance calculations

EPSG:4326 stores coordinates in degrees. For metric distance, the queries use:

```sql
geom::geography
```

For example, a 10 km proximity check is:

```sql
ST_DWithin(
    parcel.geom::geography,
    substation.geom::geography,
    10000
)
```

The distance is therefore expressed in metres.

## Spatial indexes

The core spatial tables have GiST indexes on their geometry columns. The design also includes geography-based indexes for proximity queries where appropriate.

Relational indexes support common filters such as country, region, source run, source identifier, and evidence relationships.

`queries/verify_index_usage.sql` contains representative `EXPLAIN` checks.

## Example spatial queries

Find substations close to a parcel:

```sql
SELECT
    p.source_id AS parcel_id,
    s.source_id AS substation_id,
    ST_Distance(
        p.geom::geography,
        s.geom::geography
    ) AS distance_m
FROM iris_core.parcel p
JOIN iris_core.substation s
  ON s.country_code = p.country_code
WHERE p.source_id = 'parcel-001'
ORDER BY distance_m;
```

Find parcels intersecting peatland:

```sql
SELECT
    p.source_id AS parcel_id,
    pl.source_id AS peatland_id
FROM iris_core.parcel p
JOIN iris_core.peatland pl
  ON pl.country_code = p.country_code
WHERE ST_Intersects(p.geom, pl.geom);
```

The country condition is intentional: a spatial relationship alone should not allow an entity from another country to participate in the result.

## Evidence and uncertainty

The `evidence` table stores supporting information associated with one core entity.

An evidence record contains source information, a source run, an evidence type, an uncertainty value, and a JSONB payload.

The fixture uses `illustrative` uncertainty. It does not represent production validation.

## Resetting the database

For a clean local rebuild:

```bash
./scripts/reset_db.sh
```

To remove the entire Docker database volume:

```powershell
docker compose down -v
docker compose up -d
```

**Warning:** `docker compose down -v` deletes the local PostgreSQL volume and all data stored in it.

## Design boundaries

This repository intentionally does not model:

- production credentials or secrets;
- real external data-provider integrations;
- land ownership workflows;
- planning approval;
- grid connection reservations;
- confirmed grid capacity;
- environmental or legal eligibility;
- permits;
- construction readiness.

The fixture data is synthetic. The database demonstrates schema and spatial-query patterns; it does not claim that any location is suitable for development.

## Assumptions

1. `country_code` follows a two-letter uppercase format.
2. `source_id` is unique within a country rather than globally.
3. EPSG:4326 is the canonical storage CRS.
4. Metric distance is calculated using PostGIS geography.
5. `evidence.value` is JSONB because the pilot does not define a detailed evidence payload.
6. Staging uses a generic `ingest_record` table rather than reproducing every external provider's raw schema.
7. Fixtures are deterministic so the same checks can be repeated from a clean database.

## Validation before submission

From a clean checkout:

```bash
docker compose up -d
./scripts/wait_for_db.sh
./scripts/reset_db.sh
./scripts/verify.sh
```

Then run:

```bash
make test
```

A successful validation should demonstrate that:

- the schema can be rebuilt;
- constraints are active;
- deterministic fixtures load;
- spatial queries return the expected relationships;
- spatial indexes are available to representative query plans;
- automated tests pass.

## Uncertainty boundary

This pilot is a database and spatial-screening demonstration.

A spatial match, a nearby substation, an intersecting environmental layer, or an evidence record does **not** mean that a site is approved, available, buildable, connected, or legally eligible.

Those decisions require authoritative external data and additional business processes outside the scope of this pilot.
#   i r i s - p o s t g i s - p i l o t  
 