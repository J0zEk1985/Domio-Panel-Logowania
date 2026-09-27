#!/usr/bin/env bash
# Uruchom NA VPS w katalogu docker-compose self-hosted Supabase.
#   ./import-schema-vps.sh /ścieżka/do/schema_initial.sql
set -euo pipefail
SQL="${1:-supabase/schema_initial.sql}"
if [[ ! -f "$SQL" ]]; then
  echo "Brak pliku $SQL" >&2
  exit 1
fi
docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "$SQL"
docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "
SELECT
  (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname <> 'spatial_ref_sys') AS tables,
  (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'v'
      AND c.relname NOT IN ('geography_columns','geometry_columns','raster_columns','raster_overviews')) AS views,
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public','private') AND p.prokind IN ('f','p','w')
      AND NOT EXISTS (
        SELECT 1 FROM pg_depend d JOIN pg_extension e ON e.oid = d.refobjid
        WHERE d.objid = p.oid AND d.deptype = 'e')) AS app_functions,
  (SELECT count(*) FROM pg_policies WHERE schemaname IN ('public','storage')) AS policies,
  (SELECT count(*) FROM storage.buckets) AS buckets,
  (SELECT count(*) FROM auth.users WHERE email = 'jozefiakmar@gmail.com') AS admin_users;
"
