-- Platform contact details (schema.org Organization / Polish company imprint).
-- Public read via existing page_content RLS; platform admin can update.

INSERT INTO public.page_content (content_key, section_name, description, content_value, sort_order)
VALUES
  (
    'contact_name',
    'Dane kontaktowe',
    'Nazwa firmy lub podmiotu',
    '',
    10
  ),
  (
    'contact_address',
    'Dane kontaktowe',
    'Adres korespondencyjny (ulica, numer, kod pocztowy, miejscowość)',
    '',
    20
  ),
  (
    'contact_registered_office',
    'Dane kontaktowe',
    'Siedziba (miejscowość lub adres siedziby)',
    '',
    30
  ),
  (
    'contact_phone',
    'Dane kontaktowe',
    'Telefon kontaktowy (zalecany format międzynarodowy, np. +48 123 456 789)',
    '',
    40
  ),
  (
    'contact_email',
    'Dane kontaktowe',
    'Adres e-mail kontaktowy',
    '',
    50
  )
ON CONFLICT (content_key) DO NOTHING;
