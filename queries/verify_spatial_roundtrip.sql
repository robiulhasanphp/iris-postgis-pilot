-- Parcel/substation proximity in metres.
SELECT
    p.source_id AS parcel_source_id,
    s.source_id AS substation_source_id,
    round(
        ST_Distance(p.geom::geography, s.geom::geography)::numeric,
        2
    ) AS distance_m
FROM iris_core.parcel p
JOIN iris_core.substation s
  ON p.country_code = s.country_code
WHERE p.country_code = 'GB'
  AND p.source_id = 'parcel-001'
  AND ST_DWithin(
      p.geom::geography,
      s.geom::geography,
      10000
  )
ORDER BY distance_m;

-- Parcel/peatland intersection.
SELECT
    p.source_id AS parcel_source_id,
    pl.source_id AS peatland_source_id
FROM iris_core.parcel p
JOIN iris_core.peatland pl
  ON p.country_code = pl.country_code
 AND ST_Intersects(p.geom, pl.geom)
WHERE p.country_code = 'GB'
ORDER BY p.source_id, pl.source_id;
