-- =====================================================
-- RPC: get_resident_warranty_issues
-- =====================================================
-- Zwraca listę usterek deweloperskich dla mieszkańca
-- Filtruje po community_id z location_access danego mieszkańca
-- Wymaga uwierzytelnienia (auth.uid())

CREATE OR REPLACE FUNCTION public.get_resident_warranty_issues()
RETURNS TABLE (
  id UUID,
  community_id UUID,
  community_name TEXT,
  title TEXT,
  description TEXT,
  category TEXT,
  status developer_warranty_issue_status,
  location_description TEXT,
  photos TEXT[],
  photos_completion TEXT[],
  rejection_reason TEXT,
  reported_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  comments_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_resident_community_id UUID;
  v_warranty_enabled BOOLEAN;
BEGIN
  -- Sprawdź, czy mieszkaniec ma przypisaną wspólnotę
  SELECT cl.community_id
  INTO v_resident_community_id
  FROM public.location_access la
  JOIN public.cleaning_locations cl ON cl.id = la.location_id
  WHERE la.profile_id = auth.uid()
    AND cl.community_id IS NOT NULL
  LIMIT 1;

  IF v_resident_community_id IS NULL THEN
    -- Brak community_id -> zwróć pusty wynik
    RETURN;
  END IF;

  -- Sprawdź, czy widok usterek jest włączony dla tej lokalizacji
  SELECT COALESCE(rc.enable_developer_warranty_view, FALSE)
  INTO v_warranty_enabled
  FROM public.resident_configs rc
  JOIN public.location_access la ON la.location_id = rc.location_id
  WHERE la.profile_id = auth.uid()
  LIMIT 1;

  IF NOT COALESCE(v_warranty_enabled, FALSE) THEN
    -- Funkcja wyłączona dla tego mieszkańca -> zwróć pusty wynik
    RETURN;
  END IF;

  -- Zwróć usterki tylko tej wspólnoty
  RETURN QUERY
  SELECT 
    dwi.id,
    dwi.community_id,
    c.name AS community_name,
    dwi.title,
    dwi.description,
    dwi.category,
    dwi.status,
    dwi.location_description,
    dwi.photos,
    dwi.photos_completion,
    dwi.rejection_reason,
    dwi.reported_at,
    dwi.created_at,
    dwi.updated_at,
    (
      SELECT COUNT(*)::BIGINT
      FROM public.developer_warranty_issue_comments dwic
      WHERE dwic.issue_id = dwi.id
    ) AS comments_count
  FROM public.developer_warranty_issues dwi
  JOIN public.communities c ON c.id = dwi.community_id
  WHERE dwi.community_id = v_resident_community_id
    AND dwi.status != 'draft'  -- Mieszkańcy nie widzą szkiców
  ORDER BY dwi.reported_at DESC NULLS LAST, dwi.created_at DESC;
END;
$$;

COMMENT ON FUNCTION public.get_resident_warranty_issues IS 
'Pobiera usterki deweloperskie części wspólnych dla zalogowanego mieszkańca (tylko jeśli włączone w resident_configs)';

-- Grant
GRANT EXECUTE ON FUNCTION public.get_resident_warranty_issues() TO authenticated;


-- =====================================================
-- RPC: get_resident_warranty_issue_details
-- =====================================================
-- Zwraca szczegóły pojedynczej usterki + komentarze (read-only)

CREATE OR REPLACE FUNCTION public.get_resident_warranty_issue_details(p_issue_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_resident_community_id UUID;
  v_warranty_enabled BOOLEAN;
  v_issue_community_id UUID;
  v_result JSON;
BEGIN
  -- Sprawdź community_id mieszkańca
  SELECT cl.community_id
  INTO v_resident_community_id
  FROM public.location_access la
  JOIN public.cleaning_locations cl ON cl.id = la.location_id
  WHERE la.profile_id = auth.uid()
    AND cl.community_id IS NOT NULL
  LIMIT 1;

  IF v_resident_community_id IS NULL THEN
    RAISE EXCEPTION 'Brak przypisanej wspólnoty dla tego mieszkańca';
  END IF;

  -- Sprawdź, czy widok jest włączony
  SELECT COALESCE(rc.enable_developer_warranty_view, FALSE)
  INTO v_warranty_enabled
  FROM public.resident_configs rc
  JOIN public.location_access la ON la.location_id = rc.location_id
  WHERE la.profile_id = auth.uid()
  LIMIT 1;

  IF NOT COALESCE(v_warranty_enabled, FALSE) THEN
    RAISE EXCEPTION 'Widok usterek deweloperskich jest wyłączony dla Twojego lokalu';
  END IF;

  -- Sprawdź, czy usterka należy do tej wspólnoty
  SELECT community_id INTO v_issue_community_id
  FROM public.developer_warranty_issues
  WHERE id = p_issue_id;

  IF v_issue_community_id IS NULL THEN
    RAISE EXCEPTION 'Usterka nie istnieje';
  END IF;

  IF v_issue_community_id != v_resident_community_id THEN
    RAISE EXCEPTION 'Nie masz dostępu do tej usterki';
  END IF;

  -- Zbuduj JSON z usterką + komentarzami
  SELECT json_build_object(
    'issue', (
      SELECT row_to_json(t)
      FROM (
        SELECT 
          dwi.id,
          dwi.community_id,
          c.name AS community_name,
          dwi.title,
          dwi.description,
          dwi.category,
          dwi.status,
          dwi.location_description,
          dwi.photos,
          dwi.photos_completion,
          dwi.rejection_reason,
          dwi.reported_at,
          dwi.created_at,
          dwi.updated_at
        FROM public.developer_warranty_issues dwi
        JOIN public.communities c ON c.id = dwi.community_id
        WHERE dwi.id = p_issue_id
      ) t
    ),
    'comments', (
      SELECT COALESCE(json_agg(row_to_json(cmt) ORDER BY cmt.created_at ASC), '[]'::json)
      FROM (
        SELECT 
          dwic.id,
          dwic.issue_id,
          dwic.author_type,
          dwic.content,
          dwic.created_at
        FROM public.developer_warranty_issue_comments dwic
        WHERE dwic.issue_id = p_issue_id
      ) cmt
    )
  )
  INTO v_result;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.get_resident_warranty_issue_details IS 
'Zwraca szczegóły usterki deweloperskiej + komentarze dla mieszkańca (read-only)';

GRANT EXECUTE ON FUNCTION public.get_resident_warranty_issue_details(UUID) TO authenticated;
