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
CREATE TABLE public.cleaning_catalog (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  name text NOT NULL,
  unit text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cleaning_catalog_pkey PRIMARY KEY (id)
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
  catalog_item_id uuid,
  CONSTRAINT cleaning_inventory_pkey PRIMARY KEY (id),
  CONSTRAINT cleaning_inventory_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id),
  CONSTRAINT cleaning_inventory_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.cleaning_catalog(id)
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
  coordinator_notes text,
  monthly_fee numeric DEFAULT 0,
  hourly_rate_cleaning numeric DEFAULT 0,
  hourly_rate_snow numeric DEFAULT 0,
  coordinator_can_view_financials boolean DEFAULT false,
  monthly_salary numeric DEFAULT 0,
  cleaning_rate numeric DEFAULT 0,
  snow_removal_rate numeric DEFAULT 0,
  google_place_id text,
  latitude double precision,
  longitude double precision,
  auto_notify_issues boolean DEFAULT false,
  client_notification_email text,
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
  actual_performer_id uuid,
  checklist jsonb DEFAULT '{}'::jsonb,
  task_type USER-DEFINED NOT NULL DEFAULT 'sop_standard'::task_type CHECK (task_type = ANY (ARRAY['sop_standard'::task_type, 'coordinator_single'::task_type, 'long_term'::task_type, 'employee_extra'::task_type])),
  CONSTRAINT cleaning_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT cleaning_tasks_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.property_sections(id),
  CONSTRAINT cleaning_tasks_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id),
  CONSTRAINT cleaning_tasks_assigned_staff_id_fkey FOREIGN KEY (assigned_staff_id) REFERENCES auth.users(id),
  CONSTRAINT cleaning_tasks_actual_performer_id_fkey FOREIGN KEY (actual_performer_id) REFERENCES auth.users(id)
);
CREATE TABLE public.fuel_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  vehicle_id uuid NOT NULL,
  driver_id uuid NOT NULL,
  date date NOT NULL DEFAULT CURRENT_DATE,
  cost numeric NOT NULL,
  liters numeric NOT NULL,
  fuel_type text NOT NULL,
  current_mileage integer NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT fuel_logs_pkey PRIMARY KEY (id),
  CONSTRAINT fuel_logs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT fuel_logs_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id),
  CONSTRAINT fuel_logs_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.location_access (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  location_id uuid,
  user_id uuid,
  access_type text DEFAULT 'permanent'::text,
  expires_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT location_access_pkey PRIMARY KEY (id),
  CONSTRAINT location_access_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id),
  CONSTRAINT location_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
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
  permissions jsonb DEFAULT '{"can_view_finances": false, "can_edit_schedules": true, "can_view_personnel": true, "can_manage_inventory": true, "can_edit_property_settings": false}'::jsonb,
  CONSTRAINT memberships_pkey PRIMARY KEY (id),
  CONSTRAINT memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT memberships_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id)
);
CREATE TABLE public.notification_templates (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type text NOT NULL UNIQUE,
  subject text NOT NULL,
  body_template text NOT NULL,
  days_before integer NOT NULL DEFAULT 7,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notification_templates_pkey PRIMARY KEY (id)
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
  tenant_id text UNIQUE,
  database_url text,
  global_coordinator_view_financials boolean DEFAULT false,
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
  preferences jsonb DEFAULT '{}'::jsonb,
  emergency_contact jsonb DEFAULT '{"name": "", "phone": "", "relation": ""}'::jsonb,
  internal_notes text,
  base_hourly_rate numeric DEFAULT 28.50,
  snow_hourly_rate numeric DEFAULT 35.00,
  account_type text DEFAULT 'standard'::text,
  fixed_salary numeric DEFAULT 0,
  address text,
  email text,
  phone text,
  license_no text,
  is_first_login boolean DEFAULT true,
  fleet_role USER-DEFINED DEFAULT 'driver'::fleet_role,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.property_checklists (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  location_id uuid,
  name text NOT NULL,
  requires_photo boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  section_id uuid,
  frequency text DEFAULT 'Codziennie'::text,
  frequency_config jsonb DEFAULT '{"type": "daily"}'::jsonb,
  is_active boolean DEFAULT true,
  CONSTRAINT property_checklists_pkey PRIMARY KEY (id),
  CONSTRAINT property_checklists_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id),
  CONSTRAINT property_checklists_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.property_sections(id)
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
  notification_status text DEFAULT 'pending'::text,
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
  sort_order integer DEFAULT 0,
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
CREATE TABLE public.staff_equipment (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL,
  org_id uuid NOT NULL,
  type text NOT NULL CHECK (type = ANY (ARRAY['key'::text, 'card'::text, 'tool'::text, 'other'::text])),
  name text NOT NULL,
  assigned_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT staff_equipment_pkey PRIMARY KEY (id),
  CONSTRAINT staff_equipment_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id),
  CONSTRAINT staff_equipment_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id)
);
CREATE TABLE public.staff_financial_adjustments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  amount numeric NOT NULL,
  reason text,
  adjustment_date date DEFAULT CURRENT_DATE,
  type text CHECK (type = ANY (ARRAY['bonus'::text, 'potrącenie'::text, 'korekta_godzin'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT staff_financial_adjustments_pkey PRIMARY KEY (id),
  CONSTRAINT staff_financial_adjustments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.staff_payouts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL,
  org_id uuid NOT NULL,
  month integer NOT NULL CHECK (month >= 1 AND month <= 12),
  year integer NOT NULL CHECK (year >= 2020 AND year <= 2100),
  total_amount numeric NOT NULL,
  paid_at timestamp with time zone DEFAULT now(),
  paid_by uuid,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT staff_payouts_pkey PRIMARY KEY (id),
  CONSTRAINT staff_payouts_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id),
  CONSTRAINT staff_payouts_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT staff_payouts_paid_by_fkey FOREIGN KEY (paid_by) REFERENCES public.profiles(id)
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
CREATE TABLE public.task_step_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  task_id uuid,
  user_id uuid,
  step_name text,
  created_at timestamp with time zone DEFAULT now(),
  photo_url text,
  is_extra_task boolean DEFAULT false,
  CONSTRAINT task_step_logs_pkey PRIMARY KEY (id),
  CONSTRAINT task_step_logs_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.cleaning_tasks(id),
  CONSTRAINT task_step_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.vehicles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  model text NOT NULL,
  year integer NOT NULL,
  vin text NOT NULL UNIQUE,
  reg_no text NOT NULL UNIQUE,
  mileage integer NOT NULL DEFAULT 0,
  tire_info text,
  insurance_expiry date NOT NULL,
  next_inspection date NOT NULL,
  tire_change_date date,
  assigned_driver_id uuid,
  policy_url text,
  reg_doc_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT vehicles_pkey PRIMARY KEY (id),
  CONSTRAINT vehicles_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT vehicles_assigned_driver_id_fkey FOREIGN KEY (assigned_driver_id) REFERENCES public.profiles(id)
);