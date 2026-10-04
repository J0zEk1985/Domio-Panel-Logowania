BEGIN;

ALTER TABLE public.user_consents
  DROP CONSTRAINT IF EXISTS user_consents_document_type_chk;

ALTER TABLE public.user_consents
  ADD CONSTRAINT user_consents_document_type_chk
  CHECK (document_type IN ('terms', 'privacy', 'marketing', 'cookies'));

COMMENT ON CONSTRAINT user_consents_document_type_chk ON public.user_consents IS
  'Platform legal documents in the durable consent log. Cookie category choices stay in cookie_consents.';

COMMIT;
