-- =====================================================
-- Migracja: Dodanie flagi widoczności usterek deweloperskich w aplikacji Home
-- =====================================================
-- Dodaje kolumnę enable_developer_warranty_view do resident_configs
-- Wartość domyślna: false (Admin musi włączyć ręcznie w CommunityWarrantyTab)

ALTER TABLE public.resident_configs
ADD COLUMN IF NOT EXISTS enable_developer_warranty_view BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.resident_configs.enable_developer_warranty_view IS 
'Czy mieszkańcy widzą rejestr usterek deweloperskich części wspólnych w aplikacji Home';

-- Opcjonalnie: Włącz dla testowej wspólnoty (zastąp UUID swoim community_id)
-- UPDATE public.resident_configs 
-- SET enable_developer_warranty_view = TRUE 
-- WHERE org_id IN (
--   SELECT org_id FROM communities WHERE id = 'your-community-uuid-here'
-- );
