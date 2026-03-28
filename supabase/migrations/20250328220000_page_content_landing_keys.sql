-- Align page_content keys with landing page (hero_headline, about_text, etc.)

DELETE FROM public.page_content WHERE content_key IN ('hero_title', 'hero_subtitle');

INSERT INTO public.page_content (content_key, section_name, description, content_value, sort_order) VALUES
  ('hero_headline', 'Sekcja Główna (Hero)', 'Nagłówek H1', 'Zarządzaj swoją firmą z DOMIO', 1),
  ('hero_subheadline', 'Sekcja Główna (Hero)', 'Podtytuł', 'Jeden system do wszystkiego: mieszkania, biura i cała Twoja firma w jednym miejscu.', 2),
  ('hero_button_text', 'Sekcja Główna (Hero)', 'Tekst głównego przycisku (użytkownik niezalogowany)', 'Rozpocznij darmowy test', 3),
  ('about_text', 'O nas', 'Tekst sekcji O nas', 'DOMIO łączy mieszkańców, firmy i zarządców w jednej modularnej platformie. Dopasuj moduły do siebie i rozwijaj operacje bez rozproszenia narzędzi.', 1),
  ('footer_copyright', 'Stopka', 'Tekst praw autorskich (cała linia)', '© 2026 DOMIO. Wszelkie prawa zastrzeżone.', 1)
ON CONFLICT (content_key) DO UPDATE SET
  section_name = EXCLUDED.section_name,
  description = EXCLUDED.description,
  content_value = EXCLUDED.content_value,
  sort_order = EXCLUDED.sort_order;
