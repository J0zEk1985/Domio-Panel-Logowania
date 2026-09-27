# Supabase: baseline VPS i migracje

Katalog kanoniczny schematu wspólnej bazy Domio (Cloud → self-hosted na VPS).

## Baseline (jednorazowo)

`schema_initial.sql` to zrzut **samej struktury** z projektu Cloud `bmozhsbcwpufovwnmjeb` (tabele, enumy, funkcje SQL, widoki, triggery, RLS, granty, puste buckety Storage) plus konto platform admin `jozefiakmar@gmail.com`. **Bez danych najemców.**

Plik zawiera hash hasła admina (bcrypt). Nie publikuj go poza prywatnym repo / VPS.

Odtwórz dump z katalogu Cloud (MCP `execute_sql` → pliki w `agent-tools`):

```bash
node scripts/assemble-schema.mjs
```

### Import na VPS

Postgres na `db.j0zek.pl` **nie nasłuchuje publicznie** na 5432/6543. Importuj **na serwerze**, w sieci Dockera:

```bash
# w katalogu docker-compose self-hosted Supabase
docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  < /ścieżka/schema_initial.sql
```

Albo, jeśli masz connection string tylko z localhost / VPN:

```powershell
$env:VPS_DATABASE_URL = "postgres://postgres:HASLO@127.0.0.1:5432/postgres"
.\scripts\import-schema-vps.ps1
```

**Nie** odtwarzaj historycznych plików z `migrations/` na instancji już zainicjowanej tym baseline.

### Oczekiwane liczby (Cloud, 2026-09-21)

| Obiekt | Liczba |
| --- | --- |
| tabele `public` (bez `spatial_ref_sys`) | 104 |
| widoki aplikacyjne | 4 |
| funkcje `public` + `private` (bez extension) | 418 |
| polityki RLS (`public` + `storage`) | 286 |
| triggery `public` | 105 |
| buckety Storage (puste) | 8 |
| `auth.users` admin | 1 |

## Kolejne migracje

Każda nowa migracja z `npx supabase db diff` **musi** być w transakcji:

```sql
BEGIN;

-- zapytania ALTER / CREATE

COMMIT;
```

Reguła Cursora: `.cursor/rules/supabase-migrations.mdc`.

Nowe pliki tylko **po** dacie baseline, potem:

```bash
psql "$VPS_DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/<plik>.sql
```

## Edge Functions

Źródła lokalne i komendy `scp` + `docker compose restart functions --no-deps`: `scripts/deploy-edge-functions-vps.ps1`.

Nie wdrażaj `wipe-storage-test-phase` (tylko Cloud / test).
