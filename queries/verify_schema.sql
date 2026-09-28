-- PostgreSQL/PostGIS versions
SELECT version();
SELECT PostGIS_Full_Version();

-- Required tables
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('iris_staging', 'iris_core')
ORDER BY table_schema, table_name;

-- Canonical fields
SELECT table_schema, table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'iris_core'
  AND column_name IN (
      'geom', 'country_code', 'region_code',
      'source_id', 'source_date', 'created_at'
  )
ORDER BY table_name, column_name;

-- Geometry contracts
SELECT
    f_table_schema,
    f_table_name,
    f_geometry_column,
    type,
    srid
FROM public.geometry_columns
WHERE f_table_schema = 'iris_core'
ORDER BY f_table_name;
