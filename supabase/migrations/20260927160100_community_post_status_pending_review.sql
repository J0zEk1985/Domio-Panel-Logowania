BEGIN;

ALTER TYPE public.community_post_status ADD VALUE IF NOT EXISTS 'pending_review';

COMMIT;
