ANALYZE iris_core.parcel;
ANALYZE iris_core.substation;
ANALYZE iris_core.peatland;

-- The fixture is intentionally tiny. Disable sequential scans only for this
-- diagnostic so the intended GiST access paths are visible deterministically.
BEGIN;
SET LOCAL enable_seqscan = off;

EXPLAIN (COSTS OFF)
SELECT p.id
FROM iris_core.parcel p
WHERE ST_Intersects(
    p.geom,
    ST_MakeEnvelope(-0.13, 51.49, -0.10, 51.52, 4326)
);

EXPLAIN (COSTS OFF)
SELECT s.id
FROM iris_core.substation s
WHERE ST_DWithin(
    s.geom::geography,
    ST_SetSRID(ST_MakePoint(-0.115, 51.505), 4326)::geography,
    10000
);

EXPLAIN (COSTS OFF)
SELECT p.id, pl.id
FROM iris_core.parcel p
JOIN iris_core.peatland pl
  ON p.country_code = pl.country_code
 AND ST_Intersects(p.geom, pl.geom)
WHERE p.country_code = 'GB';

COMMIT;
