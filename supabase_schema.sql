-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.applications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  domain_url text NOT NULL UNIQUE,
  api_url text,
  is_free boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT applications_pkey PRIMARY KEY (id)
);
CREATE TABLE public.cleaning_clients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  name text NOT NULL,
  email text,
  phone text,
  contract_details jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cleaning_clients_pkey PRIMARY KEY (id)
);
CREATE TABLE public.cleaning_inventory (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  location_id uuid,
  item_name text NOT NULL,
  current_quantity numeric DEFAULT 0,
  unit text DEFAULT 'liters'::text,
  min_threshold numeric DEFAULT 1.0,
  last_restock_at timestamp with time zone,
  CONSTRAINT cleaning_inventory_pkey PRIMARY KEY (id),
  CONSTRAINT cleaning_inventory_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id)
);
CREATE TABLE public.cleaning_locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  client_id uuid,
  address text NOT NULL,
  geo_location USER-DEFINED,
  geofence_radius_meters integer DEFAULT 50,
  square_meters numeric,
  access_code text,
  instruction_notes text,
  validation_config jsonb DEFAULT '{"qr_required": true, "gps_required": true, "biometric_required": false}'::jsonb,
  visibility_config jsonb DEFAULT '{"public_status": false, "manager_photos": true}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  qr_code_token text DEFAULT (gen_random_uuid())::text UNIQUE,
  CONSTRAINT cleaning_locations_pkey PRIMARY KEY (id),
  CONSTRAINT cleaning_locations_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.cleaning_clients(id)
);
CREATE TABLE public.cleaning_staff (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid,
  full_name text NOT NULL,
  phone text,
  internal_id text,
  pin text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cleaning_staff_pkey PRIMARY KEY (id),
  CONSTRAINT cleaning_staff_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id)
);
CREATE TABLE public.cleaning_tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  location_id uuid,
  assigned_staff_id uuid,
  status USER-DEFINED DEFAULT 'pending'::task_status,
  priority USER-DEFINED DEFAULT 'medium'::priority_level,
  scheduled_at timestamp with time zone NOT NULL,
  started_at timestamp with time zone,
  completed_at timestamp with time zone,
  check_in_metadata jsonb,
  check_out_metadata jsonb,
  created_at timestamp with time zone DEFAULT now(),
  coordinator_notes text,
  staff_notes text,
  section_id uuid,
  CONSTRAINT cleaning_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT cleaning_tasks_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.property_sections(id),
  CONSTRAINT cleaning_tasks_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id),
  CONSTRAINT cleaning_tasks_assigned_staff_id_fkey FOREIGN KEY (assigned_staff_id) REFERENCES auth.users(id)
);
CREATE TABLE public.locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid,
  full_address text NOT NULL,
  city text,
  postal_code text,
  google_place_id text UNIQUE,
  latitude double precision,
  longitude double precision,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT locations_pkey PRIMARY KEY (id),
  CONSTRAINT locations_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id)
);
CREATE TABLE public.material_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid,
  location_id uuid,
  requester_id uuid,
  items jsonb NOT NULL,
  notes text,
  status text DEFAULT 'pending'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT material_requests_pkey PRIMARY KEY (id),
  CONSTRAINT material_requests_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT material_requests_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id),
  CONSTRAINT material_requests_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.memberships (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  org_id uuid NOT NULL,
  role text NOT NULL CHECK (role = ANY (ARRAY['owner'::text, 'coordinator'::text, 'cleaner'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT memberships_pkey PRIMARY KEY (id),
  CONSTRAINT memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT memberships_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id)
);
CREATE TABLE public.org_subscriptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  app_id uuid NOT NULL,
  status text DEFAULT 'active'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT org_subscriptions_pkey PRIMARY KEY (id),
  CONSTRAINT org_subscriptions_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT org_subscriptions_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.applications(id)
);
CREATE TABLE public.organizations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  created_at timestamp with time zone DEFAULT now(),
  owner_id uuid,
  CONSTRAINT organizations_pkey PRIMARY KEY (id),
  CONSTRAINT organizations_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES auth.users(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  accepted_terms_at timestamp with time zone NOT NULL,
  ip_address text,
  marketing_consent boolean DEFAULT false,
  updated_at timestamp with time zone DEFAULT now(),
  terms_version text DEFAULT '1.0'::text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.property_checklists (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  location_id uuid,
  task_name text NOT NULL,
  requires_photo boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT property_checklists_pkey PRIMARY KEY (id),
  CONSTRAINT property_checklists_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id)
);
CREATE TABLE public.property_issues (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid,
  location_id uuid,
  reporter_id uuid,
  description text,
  photo_url text,
  status text DEFAULT 'open'::text CHECK (status = ANY (ARRAY['open'::text, 'resolved'::text, 'ignored'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT property_issues_pkey PRIMARY KEY (id),
  CONSTRAINT property_issues_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT property_issues_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id),
  CONSTRAINT property_issues_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.property_sections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  location_id uuid,
  name text NOT NULL,
  assigned_staff_id uuid,
  allow_cross_access boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT property_sections_pkey PRIMARY KEY (id),
  CONSTRAINT property_sections_assigned_staff_id_fkey FOREIGN KEY (assigned_staff_id) REFERENCES public.profiles(id),
  CONSTRAINT property_sections_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id)
);
CREATE TABLE public.spatial_ref_sys (
  srid integer NOT NULL CHECK (srid > 0 AND srid <= 998999),
  auth_name character varying,
  auth_srid integer,
  srtext character varying,
  proj4text character varying,
  CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid)
);
CREATE TABLE public.task_execution_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  task_id uuid,
  user_id uuid,
  action_type text NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT task_execution_logs_pkey PRIMARY KEY (id),
  CONSTRAINT task_execution_logs_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.cleaning_tasks(id),
  CONSTRAINT task_execution_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);