BEGIN;

-- Obvious profanity is rejected on every insert and content update.
-- The Home app also sends comments through verify-comment, which uses the
-- same classifier as announcements for insults that are not in this stem list.
-- Keep the stem list aligned with supabase/functions/_shared/jevComment.ts.

CREATE OR REPLACE FUNCTION private.community_comment_has_profanity(p_content text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO private, public
AS $$
DECLARE
  folded text;
  parts text[];
  tokens text[] := ARRAY[]::text[];
  candidates text[] := ARRAY[]::text[];
  letters text := '';
  token text;
  i int;
  n int;
  stem text;
  stems text[] := ARRAY[
    'kurw', 'chuj', 'huj', 'jeb', 'pierdol', 'pierdal', 'pierdz', 'pizd',
    'cipa', 'cipk', 'kutas', 'fiut', 'cwel', 'dziwk', 'sukinsyn',
    'gowno', 'gowna', 'gownie', 'gownem', 'gowien',
    'zjeb', 'pojeb', 'wjeb', 'najeb', 'ujeb', 'dojeb', 'rozjeb', 'zajeb',
    'wyjeb', 'odjeb', 'podjeb', 'przyjeb', 'przejeb',
    'fuck', 'shit', 'bitch', 'asshole', 'cunt', 'motherfuck',
    'nigger', 'nigga', 'faggot', 'whore', 'slut'
  ];
  exact_tokens text[] := ARRAY['suka', 'suki', 'suko', 'suke', 'sucz'];
BEGIN
  IF p_content IS NULL OR btrim(p_content) = '' THEN
    RETURN false;
  END IF;

  folded := lower(p_content);
  folded := translate(folded, 'ąćęłńóśźż', 'acelnoszz');
  folded := replace(folded, '0', 'o');
  folded := replace(folded, '1', 'i');
  folded := replace(folded, '!', 'i');
  folded := replace(folded, '3', 'e');
  folded := replace(folded, '4', 'a');
  folded := replace(folded, '@', 'a');
  folded := replace(folded, '5', 's');
  folded := replace(folded, '$', 's');
  folded := replace(folded, '7', 't');

  parts := regexp_split_to_array(folded, '[^a-z]+');
  FOREACH token IN ARRAY parts LOOP
    IF token IS NULL OR token = '' THEN
      CONTINUE;
    END IF;
    tokens := tokens || regexp_replace(token, '(.)\1+', '\1', 'g');
  END LOOP;

  candidates := tokens;
  n := coalesce(array_length(tokens, 1), 0);

  FOR i IN 1..n LOOP
    IF length(tokens[i]) = 1 THEN
      letters := letters || tokens[i];
    ELSE
      IF length(letters) >= 4 THEN
        candidates := candidates || letters;
      END IF;
      letters := '';
    END IF;
  END LOOP;
  IF length(letters) >= 4 THEN
    candidates := candidates || letters;
  END IF;

  IF n >= 2 THEN
    FOR i IN 1..n - 1 LOOP
      IF length(tokens[i]) <= 3 AND length(tokens[i + 1]) <= 3 THEN
        candidates := candidates || (tokens[i] || tokens[i + 1]);
      END IF;
    END LOOP;
  END IF;

  FOREACH token IN ARRAY candidates LOOP
    IF token = ANY (exact_tokens) THEN
      RETURN true;
    END IF;
    FOREACH stem IN ARRAY stems LOOP
      IF token = stem OR left(token, length(stem)) = stem THEN
        RETURN true;
      END IF;
      IF (length(stem) >= 4 OR stem = 'jeb') AND position(stem IN token) > 0 THEN
        RETURN true;
      END IF;
    END LOOP;
  END LOOP;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION private.community_comment_has_profanity(text) FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.enforce_community_comment_language()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO private, public
AS $$
BEGIN
  IF private.community_comment_has_profanity(COALESCE(NEW.content, '')) THEN
    RAISE EXCEPTION 'Komentarz zawiera wulgaryzmy i nie może zostać dodany.'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.enforce_community_comment_language() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.enforce_community_comment_language() TO authenticated, service_role;

DROP TRIGGER IF EXISTS trg_community_comments_reject_profanity ON public.community_comments;
CREATE TRIGGER trg_community_comments_reject_profanity
  BEFORE INSERT OR UPDATE OF content ON public.community_comments
  FOR EACH ROW
  EXECUTE FUNCTION private.enforce_community_comment_language();

DO $$
BEGIN
  IF NOT private.community_comment_has_profanity('co to kurwa jest') THEN
    RAISE EXCEPTION 'profanity gate missed: co to kurwa jest';
  END IF;
  IF NOT private.community_comment_has_profanity('k u r w a') THEN
    RAISE EXCEPTION 'profanity gate missed: spaced kurwa';
  END IF;
  IF NOT private.community_comment_has_profanity('Ja pierdolę') THEN
    RAISE EXCEPTION 'profanity gate missed: pierdolę';
  END IF;
  IF NOT private.community_comment_has_profanity('spierdalaj') THEN
    RAISE EXCEPTION 'profanity gate missed: spierdalaj';
  END IF;
  IF NOT private.community_comment_has_profanity('gówno') THEN
    RAISE EXCEPTION 'profanity gate missed: gówno';
  END IF;
  IF NOT private.community_comment_has_profanity('ty suko') THEN
    RAISE EXCEPTION 'profanity gate missed: suko';
  END IF;
  IF private.community_comment_has_profanity('dziękuję za pomoc') THEN
    RAISE EXCEPTION 'profanity gate false positive: dzięki';
  END IF;
  IF private.community_comment_has_profanity('thuja uschła przy wejściu') THEN
    RAISE EXCEPTION 'profanity gate false positive: thuja';
  END IF;
  IF private.community_comment_has_profanity('ciotka przyjedzie w sobotę') THEN
    RAISE EXCEPTION 'profanity gate false positive: ciotka';
  END IF;
  IF private.community_comment_has_profanity('pedał gazu nie działa') THEN
    RAISE EXCEPTION 'profanity gate false positive: pedał';
  END IF;
  IF private.community_comment_has_profanity('sukienka została w pralni') THEN
    RAISE EXCEPTION 'profanity gate false positive: sukienka';
  END IF;
  IF private.community_comment_has_profanity('kura warta uwagi') THEN
    RAISE EXCEPTION 'profanity gate false positive: kura warta';
  END IF;
END $$;

COMMIT;
