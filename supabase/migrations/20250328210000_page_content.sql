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
  ('hero_headline', 'Sekcja Główna (Hero)', 'Nagłówek H1', 'Zarządzaj swoją firmą z DOMIO', 1),
  ('hero_subheadline', 'Sekcja Główna (Hero)', 'Podtytuł', 'Jeden system do wszystkiego: mieszkania, biura i cała Twoja firma w jednym miejscu.', 2),
  ('hero_button_text', 'Sekcja Główna (Hero)', 'Tekst głównego przycisku (użytkownik niezalogowany)', 'Rozpocznij darmowy test', 3),
  ('about_text', 'O nas', 'Tekst sekcji O nas', 'DOMIO łączy mieszkańców, firmy i zarządców w jednej modularnej platformie. Dopasuj moduły do siebie i rozwijaj operacje bez rozproszenia narzędzi.', 1),
  ('footer_copyright', 'Stopka', 'Tekst praw autorskich (cała linia)', '© 2026 DOMIO. Wszelkie prawa zastrzeżone.', 1)
ON CONFLICT (content_key) DO NOTHING;
