# Import schema_initial.sql na self-hosted Supabase (VPS).
# Port 5432 na db.j0zek.pl jest zamknięty z internetu — skrypt działa tylko
# gdy VPS_DATABASE_URL wskazuje host osiągalny stąd (SSH tunnel / VPN / localhost).
# Na samym VPS użyj: scripts/import-schema-vps.sh
#
# Użycie:
#   $env:VPS_DATABASE_URL = "postgres://postgres:HASLO@127.0.0.1:5432/postgres"
#   .\scripts\import-schema-vps.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$sql = Join-Path $root "supabase\schema_initial.sql"

if (-not $env:VPS_DATABASE_URL) {
  Write-Error "Ustaw VPS_DATABASE_URL (connection string do Postgresa na VPS)."
}

if (-not (Test-Path $sql)) {
  Write-Error "Brak $sql — najpierw uruchom: node scripts/assemble-schema.mjs"
}

$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
  Write-Error "Brak psql w PATH. Zainstaluj klienta PostgreSQL albo uruchom na VPS: psql `$VPS_DATABASE_URL -v ON_ERROR_STOP=1 -f supabase/schema_initial.sql"
}

Write-Host "Importuję $sql"
& psql $env:VPS_DATABASE_URL -v ON_ERROR_STOP=1 -f $sql
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Weryfikacja spójności..."
& psql $env:VPS_DATABASE_URL -v ON_ERROR_STOP=1 -c @"
SELECT
  (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname <> 'spatial_ref_sys') AS tables,
  (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'v') AS views,
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname IN ('public','private') AND p.prokind IN ('f','p','w') AND NOT EXISTS (SELECT 1 FROM pg_depend d JOIN pg_extension e ON e.oid = d.refobjid WHERE d.objid = p.oid AND d.deptype = 'e')) AS app_functions,
  (SELECT count(*) FROM pg_policies WHERE schemaname IN ('public','storage')) AS policies,
  (SELECT count(*) FROM storage.buckets) AS buckets,
  (SELECT count(*) FROM auth.users WHERE email = 'jozefiakmar@gmail.com') AS admin_users;
"@
