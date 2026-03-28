-- Versioned legal documents (terms / privacy) for admin publishing
-- RLS: platform admins only

CREATE TABLE IF NOT EXISTS public.legal_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_type text NOT NULL CHECK (document_type = ANY (ARRAY['terms'::text, 'privacy'::text])),
  version text NOT NULL,
  content text NOT NULL,
  is_active boolean NOT NULL DEFAULT false,
  published_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users (id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_legal_documents_type_published
  ON public.legal_documents (document_type, published_at DESC);

ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Platform admin full access legal_documents" ON public.legal_documents;
CREATE POLICY "Platform admin full access legal_documents"
  ON public.legal_documents
  FOR ALL
  TO authenticated
  USING (public.is_platform_admin())
  WITH CHECK (public.is_platform_admin());
