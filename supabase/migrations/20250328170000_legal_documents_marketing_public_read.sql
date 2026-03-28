-- Marketing document type, is_required flag, public read of active rows (signup)

ALTER TABLE public.legal_documents DROP CONSTRAINT IF EXISTS legal_documents_document_type_check;
ALTER TABLE public.legal_documents
  ADD CONSTRAINT legal_documents_document_type_check
  CHECK (document_type = ANY (ARRAY['terms'::text, 'privacy'::text, 'marketing'::text]));

ALTER TABLE public.legal_documents
  ADD COLUMN IF NOT EXISTS is_required boolean NOT NULL DEFAULT true;

UPDATE public.legal_documents
SET is_required = true
WHERE document_type IN ('terms', 'privacy');

UPDATE public.legal_documents
SET is_required = false
WHERE document_type = 'marketing';

-- Allow anon + authenticated to read published (active) legal text for registration UI
DROP POLICY IF EXISTS "Public can read active legal documents" ON public.legal_documents;
CREATE POLICY "Public can read active legal documents"
  ON public.legal_documents
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);
