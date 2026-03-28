-- CMS: editable landing / marketing copy (keyed rows, grouped by section in admin UI)
-- RLS: platform admins read/write; public read for anonymous landing page

CREATE TABLE IF NOT EXISTS public.page_content (
  content_key text PRIMARY KEY,
  section_name text NOT NULL,
  description text NOT NULL,
  content_value text NOT NULL DEFAULT '',
  sort_order integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_page_content_section_sort
  ON public.page_content (section_name, sort_order, content_key);

ALTER TABLE public.page_content ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Platform admin full access page_content" ON public.page_content;
CREATE POLICY "Platform admin full access page_content"
  ON public.page_content
  FOR ALL
  TO authenticated
  USING (public.is_platform_admin())
  WITH CHECK (public.is_platform_admin());

DROP POLICY IF EXISTS "Public can read page content" ON public.page_content;
CREATE POLICY "Public can read page content"
  ON public.page_content
  FOR SELECT
  TO anon, authenticated
  USING (true);

INSERT INTO public.page_content (content_key, section_name, description, content_value, sort_order) VALUES
  ('hero_title', 'Sekcja Główna (Hero)', 'Nagłówek H1', 'Witaj w Domio', 1),
  ('hero_subtitle', 'Sekcja Główna (Hero)', 'Podtytuł', 'Zarządzaj firmą z jednego miejsca', 2),
  ('footer_copyright', 'Stopka', 'Tekst praw autorskich', '© 2026 Domio', 1)
ON CONFLICT (content_key) DO NOTHING;
