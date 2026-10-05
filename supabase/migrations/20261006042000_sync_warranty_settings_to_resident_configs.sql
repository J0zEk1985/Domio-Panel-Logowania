-- =====================================================
-- Migracja: Synchronizacja ustawień usterek deweloperskich do resident_configs
-- =====================================================
-- Kiedy Admin włącza/wyłącza widoczność usterek deweloperskich w community_warranty_settings,
-- automatycznie aktualizowane są wszystkie resident_configs dla budynków tej wspólnoty

-- RPC do synchronizacji
CREATE OR REPLACE FUNCTION public.sync_warranty_visibility_to_resident_configs(
  p_community_id UUID,
  p_enabled BOOLEAN
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  -- Zaktualizuj wszystkie resident_configs dla budynków w tej wspólnocie
  WITH updated AS (
    UPDATE public.resident_configs rc
    SET 
      enable_developer_warranty_view = p_enabled,
      updated_at = now()
    FROM public.cleaning_locations cl
    WHERE cl.id = rc.location_id
      AND cl.community_id = p_community_id
    RETURNING rc.id
  )
  SELECT COUNT(*) INTO v_updated_count FROM updated;

  RETURN v_updated_count;
END;
$$;

COMMENT ON FUNCTION public.sync_warranty_visibility_to_resident_configs IS 
'Synchronizuje ustawienie widoczności usterek deweloperskich z community_warranty_settings do wszystkich resident_configs budynków tej wspólnoty';

GRANT EXECUTE ON FUNCTION public.sync_warranty_visibility_to_resident_configs(UUID, BOOLEAN) TO authenticated;


-- Trigger który automatycznie synchronizuje przy zmianie community_warranty_settings
CREATE OR REPLACE FUNCTION private.trg_sync_warranty_visibility()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Synchronizuj do resident_configs po każdej zmianie
  PERFORM public.sync_warranty_visibility_to_resident_configs(
    NEW.community_id,
    NEW.resident_visibility_enabled
  );
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_warranty_settings_change
  AFTER INSERT OR UPDATE OF resident_visibility_enabled
  ON public.community_warranty_settings
  FOR EACH ROW
  EXECUTE FUNCTION private.trg_sync_warranty_visibility();

COMMENT ON TRIGGER trg_after_warranty_settings_change ON public.community_warranty_settings IS 
'Automatycznie synchronizuje resident_visibility_enabled do wszystkich resident_configs budynków wspólnoty';


-- Inicjalna synchronizacja dla istniejących danych (backfill)
-- Dla wszystkich wspólnot, które już mają ustawienia
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT community_id, resident_visibility_enabled 
    FROM public.community_warranty_settings
  LOOP
    PERFORM public.sync_warranty_visibility_to_resident_configs(
      r.community_id,
      r.resident_visibility_enabled
    );
  END LOOP;
END $$;
