-- Layer 1: company tool registry + digital handover/return protocols.
-- Keys/cards stay on staff_equipment (no company pool). Tools live in equipment_assets.
-- RLS policies, storage object policies, and RPCs are Layer 2.

-- ---------------------------------------------------------------------------
-- Company tool assets (unique instances, not quantity stock)
-- ---------------------------------------------------------------------------

CREATE TABLE public.equipment_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations (id) ON DELETE CASCADE,
  name text NOT NULL,
  category text NOT NULL DEFAULT 'tool',
  serial_number text,
  status text NOT NULL DEFAULT 'available',
  current_holder_id uuid REFERENCES public.profiles (id) ON DELETE RESTRICT,
  notes text,
  created_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT equipment_assets_name_not_blank CHECK (btrim(name) <> ''),
  CONSTRAINT equipment_assets_category_check CHECK (category = ANY (ARRAY['tool'::text, 'other'::text])),
  CONSTRAINT equipment_assets_status_check CHECK (
    status = ANY (
      ARRAY[
        'available'::text,
        'pending_handover'::text,
        'assigned'::text,
        'pending_return'::text,
        'retired'::text
      ]
    )
  ),
  CONSTRAINT equipment_assets_serial_not_blank CHECK (
    serial_number IS NULL OR btrim(serial_number) <> ''
  ),
  CONSTRAINT equipment_assets_holder_matches_status CHECK (
    (
      status = ANY (ARRAY['assigned'::text, 'pending_handover'::text, 'pending_return'::text])
      AND current_holder_id IS NOT NULL
    )
    OR (
      status = ANY (ARRAY['available'::text, 'retired'::text])
      AND current_holder_id IS NULL
    )
  )
);

COMMENT ON TABLE public.equipment_assets IS
  'Unique company tools (lawnmower, saw, etc.). At most one current holder. Keys/cards are not stored here.';

COMMENT ON COLUMN public.equipment_assets.current_holder_id IS
  'Assigned worker profile. Required when status is assigned or pending_*; must be null when available or retired.';

CREATE INDEX equipment_assets_org_id_idx
  ON public.equipment_assets (org_id);

CREATE INDEX equipment_assets_org_status_idx
  ON public.equipment_assets (org_id, status);

CREATE INDEX equipment_assets_current_holder_id_idx
  ON public.equipment_assets (current_holder_id)
  WHERE current_holder_id IS NOT NULL;

CREATE INDEX equipment_assets_created_by_idx
  ON public.equipment_assets (created_by)
  WHERE created_by IS NOT NULL;

CREATE UNIQUE INDEX equipment_assets_org_serial_unique
  ON public.equipment_assets (org_id, serial_number)
  WHERE serial_number IS NOT NULL;

CREATE TRIGGER equipment_assets_set_updated_at
  BEFORE UPDATE ON public.equipment_assets
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- Move existing tool/other rows off staff_equipment into the company registry
-- ---------------------------------------------------------------------------

INSERT INTO public.equipment_assets (
  org_id,
  name,
  category,
  status,
  current_holder_id,
  created_at,
  updated_at
)
SELECT
  se.org_id,
  se.name,
  CASE WHEN se.type = 'other' THEN 'other' ELSE 'tool' END,
  'assigned',
  se.staff_id,
  COALESCE(se.created_at, se.assigned_at, now()),
  COALESCE(se.created_at, se.assigned_at, now())
FROM public.staff_equipment se
WHERE se.type IN ('tool', 'other');

DELETE FROM public.staff_equipment
WHERE type IN ('tool', 'other');

ALTER TABLE public.staff_equipment
  DROP CONSTRAINT staff_equipment_type_check;

ALTER TABLE public.staff_equipment
  ADD CONSTRAINT staff_equipment_type_check
  CHECK (type = ANY (ARRAY['key'::text, 'card'::text, 'other'::text]));

-- ---------------------------------------------------------------------------
-- Keys/cards: keep rows on return (no hard delete)
-- ---------------------------------------------------------------------------

ALTER TABLE public.staff_equipment
  ADD COLUMN status text NOT NULL DEFAULT 'assigned',
  ADD COLUMN returned_at timestamptz,
  ADD COLUMN created_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL;

ALTER TABLE public.staff_equipment
  ADD CONSTRAINT staff_equipment_status_check CHECK (
    status = ANY (
      ARRAY[
        'pending_handover'::text,
        'assigned'::text,
        'pending_return'::text,
        'returned'::text
      ]
    )
  );

ALTER TABLE public.staff_equipment
  ADD CONSTRAINT staff_equipment_returned_at_matches_status CHECK (
    (status = 'returned' AND returned_at IS NOT NULL)
    OR (status <> 'returned' AND returned_at IS NULL)
  );

CREATE INDEX staff_equipment_created_by_idx
  ON public.staff_equipment (created_by)
  WHERE created_by IS NOT NULL;

CREATE INDEX staff_equipment_org_status_idx
  ON public.staff_equipment (org_id, status);

COMMENT ON COLUMN public.staff_equipment.status IS
  'pending_handover / assigned / pending_return / returned. Existing rows are grandfathered as assigned.';

COMMENT ON COLUMN public.staff_equipment.returned_at IS
  'Set when status becomes returned. The row is retained as history.';

-- ---------------------------------------------------------------------------
-- Digital handover / return protocols (tools and keys/cards)
-- ---------------------------------------------------------------------------

CREATE TABLE public.equipment_protocols (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations (id) ON DELETE CASCADE,
  kind text NOT NULL,
  asset_id uuid REFERENCES public.equipment_assets (id) ON DELETE RESTRICT,
  staff_equipment_id uuid REFERENCES public.staff_equipment (id) ON DELETE RESTRICT,
  worker_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  direction text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  initiated_by uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  responded_by uuid REFERENCES public.profiles (id) ON DELETE RESTRICT,
  condition_notes text,
  photo_urls text[] NOT NULL DEFAULT '{}'::text[],
  initiated_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT equipment_protocols_kind_check CHECK (kind = ANY (ARRAY['asset'::text, 'key_card'::text])),
  CONSTRAINT equipment_protocols_direction_check CHECK (direction = ANY (ARRAY['handover'::text, 'return'::text])),
  CONSTRAINT equipment_protocols_status_check CHECK (
    status = ANY (
      ARRAY['pending'::text, 'accepted'::text, 'rejected'::text, 'cancelled'::text]
    )
  ),
  CONSTRAINT equipment_protocols_item_matches_kind CHECK (
    (
      kind = 'asset'
      AND asset_id IS NOT NULL
      AND staff_equipment_id IS NULL
    )
    OR (
      kind = 'key_card'
      AND staff_equipment_id IS NOT NULL
      AND asset_id IS NULL
    )
  ),
  CONSTRAINT equipment_protocols_pending_has_no_response CHECK (
    (status = 'pending' AND responded_at IS NULL)
    OR (status <> 'pending')
  )
);

COMMENT ON TABLE public.equipment_protocols IS
  'Two-sided digital handover/return protocol. One pending protocol per item.';

COMMENT ON COLUMN public.equipment_protocols.kind IS
  'asset = equipment_assets tool; key_card = staff_equipment key or card.';

COMMENT ON COLUMN public.equipment_protocols.photo_urls IS
  'Optional condition photos in storage bucket equipment-protocols, path {org_id}/{protocol_id}/.';

CREATE INDEX equipment_protocols_org_worker_status_idx
  ON public.equipment_protocols (org_id, worker_id, status);

CREATE INDEX equipment_protocols_asset_id_idx
  ON public.equipment_protocols (asset_id)
  WHERE asset_id IS NOT NULL;

CREATE INDEX equipment_protocols_staff_equipment_id_idx
  ON public.equipment_protocols (staff_equipment_id)
  WHERE staff_equipment_id IS NOT NULL;

CREATE INDEX equipment_protocols_initiated_by_idx
  ON public.equipment_protocols (initiated_by);

CREATE INDEX equipment_protocols_responded_by_idx
  ON public.equipment_protocols (responded_by)
  WHERE responded_by IS NOT NULL;

CREATE UNIQUE INDEX equipment_protocols_one_pending_asset
  ON public.equipment_protocols (asset_id)
  WHERE status = 'pending' AND asset_id IS NOT NULL;

CREATE UNIQUE INDEX equipment_protocols_one_pending_staff_equipment
  ON public.equipment_protocols (staff_equipment_id)
  WHERE status = 'pending' AND staff_equipment_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Storage bucket (object policies are Layer 2)
-- ---------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'equipment-protocols',
  'equipment-protocols',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Grants + RLS enabled (no policies yet — deny-by-default until Layer 2)
-- ---------------------------------------------------------------------------

ALTER TABLE public.equipment_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_protocols ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.equipment_assets FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.equipment_protocols FROM anon, PUBLIC;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.equipment_assets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.equipment_protocols TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.equipment_assets TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.equipment_protocols TO service_role;
