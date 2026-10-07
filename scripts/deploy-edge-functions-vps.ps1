# Wdrożenie Edge Functions na self-hosted Supabase (VPS).
# Oficjalna metoda: skopiuj katalogi funkcji do volumes/functions/ i zrestartuj serwis.
#
# Wymagane zmienne:
#   VPS_SSH          np. user@j0zek.pl
#   VPS_FUNCTIONS_DIR  np. /opt/supabase/docker/volumes/functions
#
# Użycie:
#   $env:VPS_SSH = "user@j0zek.pl"
#   $env:VPS_FUNCTIONS_DIR = "/opt/supabase/docker/volumes/functions"
#   .\scripts\deploy-edge-functions-vps.ps1

$ErrorActionPreference = "Stop"

if (-not $env:VPS_SSH) { Write-Error "Ustaw VPS_SSH (np. debian@j0zek.pl)" }
if (-not $env:VPS_FUNCTIONS_DIR) { Write-Error "Ustaw VPS_FUNCTIONS_DIR (ścieżka volumes/functions na VPS)" }

$pairs = @(
  @{ Name = "consent"; Src = "d:\projekty\Domio-Panel-Logowania\supabase\functions\consent"; VerifyJwt = $false },
  @{ Name = "record-legal-consent"; Src = "d:\projekty\Domio-Panel-Logowania\supabase\functions\record-legal-consent"; VerifyJwt = $false },
  @{ Name = "lookup-legal-entity"; Src = "d:\projekty\Domio-Panel-Logowania\supabase\functions\lookup-legal-entity"; VerifyJwt = $true },
  @{ Name = "create-worker"; Src = "d:\projekty\Domio-Panel-Logowania\supabase\functions\create-worker"; VerifyJwt = $false },
  @{ Name = "activate-home-resident"; Src = "d:\projekty\Domio-Panel-Logowania\supabase\functions\activate-home-resident"; VerifyJwt = $false },
  @{ Name = "generate-sop-tasks"; Src = "d:\projekty\Domio-Cleaning\supabase\functions\generate-sop-tasks"; VerifyJwt = $false },
  @{ Name = "create-user"; Src = "d:\projekty\Obsluga-floty-samochodow\supabase\functions\create-user"; VerifyJwt = $false },
  @{ Name = "delete-user"; Src = "d:\projekty\Obsluga-floty-samochodow\supabase\functions\delete-user"; VerifyJwt = $false },
  @{ Name = "send-web-push"; Src = "d:\projekty\Domio-Serwis\supabase\functions\send-web-push"; VerifyJwt = $true },
  @{ Name = "triage-ai-logic"; Src = "d:\projekty\Domio-Administracja\supabase\functions\triage-ai-logic"; VerifyJwt = $true },
  @{ Name = "lodz-waste-schedule"; Src = "d:\projekty\Domio-Administracja\supabase\functions\lodz-waste-schedule"; VerifyJwt = $true }
)

Write-Host "Źródła lokalne:"
foreach ($p in $pairs) {
  if (-not (Test-Path $p.Src)) { Write-Error "Brak $($p.Src)" }
  Write-Host " - $($p.Name)  $($p.Src)"
}

Write-Host ""
Write-Host "Komendy do wykonania (scp + restart). Funkcja wipe-storage-test-phase jest tylko na Cloud — nie kopiujemy jej."
Write-Host ""

foreach ($p in $pairs) {
  Write-Host "scp -r `"$($p.Src)`" $($env:VPS_SSH):$($env:VPS_FUNCTIONS_DIR)/$($p.Name)"
}

Write-Host ""
Write-Host "ssh $($env:VPS_SSH) `"cd $(Split-Path $env:VPS_FUNCTIONS_DIR -Parent | Split-Path -Parent); docker compose restart functions --no-deps`""
Write-Host ""
Write-Host "Sekrety funkcji ustaw w docker/.env.functions na VPS (nie w repo):"
Write-Host "  SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY"
Write-Host "  GUS_BIR_KEY, GUS_BIR_ENV"
Write-Host "  LEGAL_WELCOME_N8N_WEBHOOK_URL"
Write-Host "  CONSENT_IP_SALT"
Write-Host "  WEB_PUSH_VAPID_PUBLIC_KEY, WEB_PUSH_VAPID_PRIVATE_KEY, WEB_PUSH_VAPID_SUBJECT"
Write-Host "  SOP_CRON_SECRET (nagłówek x-domio-cron-secret w cron.job)"
Write-Host "  GEMINI_API_KEY (triage-ai-logic)"
Write-Host ""
Write-Host "Po skopiowaniu zrestartuj functions i sprawdź:"
Write-Host "  curl -i https://db.j0zek.pl/functions/v1/send-web-push"
