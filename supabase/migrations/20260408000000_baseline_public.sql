-- DOMIO baseline (public schema only). Cleaned from Supabase Cloud pg_dump for self-hosted.
-- Removed: platform schemas (auth, storage, realtime, extensions, graphql, vault, …), psql \-meta lines, preamble SET/session lines, selected CREATE EXTENSION.
-- Reordered: functions (+ COMMENT) after core DDL; triggers; ALTER TABLE … ENABLE ROW LEVEL SECURITY; all CREATE POLICY; ALTER POLICY; COMMENT ON POLICY; ACL last.

--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9 (Debian 17.9-1.pgdg13+1)
--
-- Name: pg_net; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA public;

--
-- Name: EXTENSION pg_net; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_net IS 'Async HTTP';

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;

--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';

--
-- Name: community_post_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.community_post_status AS ENUM (
    'active',
    'completed',
    'cancelled',
    'deleted'
);


ALTER TYPE public.community_post_status OWNER TO postgres;

--
-- Name: community_post_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.community_post_type AS ENUM (
    'offer',
    'request',
    'event',
    'general'
);


ALTER TYPE public.community_post_type OWNER TO postgres;

--
-- Name: company_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.company_category AS ENUM (
    'contractor',
    'insurer',
    'utility',
    'other'
);


ALTER TYPE public.company_category OWNER TO postgres;

--
-- Name: eboard_msg_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.eboard_msg_status AS ENUM (
    'published',
    'pending_moderation',
    'archived'
);


ALTER TYPE public.eboard_msg_status OWNER TO postgres;

--
-- Name: eboard_msg_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.eboard_msg_type AS ENUM (
    'official',
    'advertisement',
    'resident'
);


ALTER TYPE public.eboard_msg_type OWNER TO postgres;

--
-- Name: fleet_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.fleet_role AS ENUM (
    'admin',
    'driver'
);


ALTER TYPE public.fleet_role OWNER TO postgres;

--
-- Name: inspection_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.inspection_status AS ENUM (
    'positive',
    'positive_with_defects',
    'negative'
);


ALTER TYPE public.inspection_status OWNER TO postgres;

--
-- Name: inspection_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.inspection_type AS ENUM (
    'building',
    'building_5yr',
    'chimney',
    'gas',
    'electrical',
    'fire_safety',
    'elevator_udt',
    'elevator_electrical',
    'separator',
    'hydrophore',
    'rainwater_pump',
    'sewage_pump',
    'mechanical_ventilation',
    'car_platform',
    'treatment_plant',
    'garage_door',
    'entrance_gate',
    'barrier',
    'co_lpg_detectors',
    'other'
);


ALTER TYPE public.inspection_type OWNER TO postgres;

--
-- Name: issue_priority_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.issue_priority_enum AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);


ALTER TYPE public.issue_priority_enum OWNER TO postgres;

--
-- Name: issue_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.issue_status_enum AS ENUM (
    'new',
    'open',
    'pending_admin_approval',
    'in_progress',
    'waiting_for_parts',
    'delegated',
    'resolved',
    'rejected'
);


ALTER TYPE public.issue_status_enum OWNER TO postgres;

--
-- Name: policy_scope_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.policy_scope_enum AS ENUM (
    'majątkowe',
    'oc_ogolne',
    'oc_zarzadu'
);


ALTER TYPE public.policy_scope_enum OWNER TO postgres;

--
-- Name: priority_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'emergency'
);


ALTER TYPE public.priority_level OWNER TO postgres;

--
-- Name: property_contract_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.property_contract_type AS ENUM (
    'cleaning',
    'maintenance',
    'administration',
    'elevator',
    'other'
);


ALTER TYPE public.property_contract_type OWNER TO postgres;

--
-- Name: property_task_priority; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.property_task_priority AS ENUM (
    'low',
    'medium',
    'urgent'
);


ALTER TYPE public.property_task_priority OWNER TO postgres;

--
-- Name: property_task_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.property_task_status AS ENUM (
    'todo',
    'in_progress',
    'done'
);


ALTER TYPE public.property_task_status OWNER TO postgres;

--
-- Name: property_task_visibility; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.property_task_visibility AS ENUM (
    'internal_only',
    'board_visible'
);


ALTER TYPE public.property_task_visibility OWNER TO postgres;

--
-- Name: sync_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.sync_status AS ENUM (
    'not_synced',
    'pending',
    'synced',
    'error'
);


ALTER TYPE public.sync_status OWNER TO postgres;

--
-- Name: task_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.task_status AS ENUM (
    'pending',
    'in_progress',
    'done',
    'cancelled'
);


ALTER TYPE public.task_status OWNER TO postgres;

--
-- Name: task_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.task_type AS ENUM (
    'sop_standard',
    'coordinator_single',
    'long_term',
    'employee_extra'
);


ALTER TYPE public.task_type OWNER TO postgres;

--
-- Name: unit_inspection_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.unit_inspection_status AS ENUM (
    'pending',
    'completed',
    'failed_no_access',
    'failed_defects',
    'rescheduled'
);


ALTER TYPE public.unit_inspection_status OWNER TO postgres;

--
-- Name: companies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.companies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    tax_id text NOT NULL,
    category public.company_category NOT NULL,
    email text,
    phone text,
    address text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    org_id uuid,
    CONSTRAINT companies_name_check CHECK ((length(TRIM(BOTH FROM name)) > 0)),
    CONSTRAINT companies_tax_id_check CHECK ((length(TRIM(BOTH FROM tax_id)) > 0))
);


ALTER TABLE public.companies OWNER TO postgres;

--
-- Name: TABLE companies; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.companies IS 'Global directory: one row per tax_id (NIP); shared across tenants; no org_id.';

--
-- Name: COLUMN companies.tax_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.companies.tax_id IS 'Polish NIP or equivalent; globally unique.';

--
-- Name: COLUMN companies.org_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.companies.org_id IS 'Tenant scope. NULL allowed temporarily; backfill org_id manually, then optionally SET NOT NULL.';

--
-- Name: admin_contracts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_contracts (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid,
    vendor_id uuid,
    service_scope text NOT NULL,
    start_date date NOT NULL,
    end_date date,
    monthly_value numeric(10,2),
    notice_period_days integer DEFAULT 30,
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.admin_contracts OWNER TO postgres;

--
-- Name: applications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    domain_url text NOT NULL,
    api_url text,
    is_free boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.applications OWNER TO postgres;

--
-- Name: task_execution_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_execution_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid,
    user_id uuid,
    action_type text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.task_execution_logs OWNER TO postgres;

--
-- Name: cleaner_recent_activity; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.cleaner_recent_activity WITH (security_invoker='true') AS
 SELECT id,
    task_id,
    user_id,
    action_type,
    notes,
    created_at
   FROM public.task_execution_logs
  WHERE ((user_id = auth.uid()) AND (created_at >= (now() - '24:00:00'::interval)));


ALTER VIEW public.cleaner_recent_activity OWNER TO postgres;

--
-- Name: cleaning_catalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cleaning_catalog (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    name text NOT NULL,
    unit text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.cleaning_catalog OWNER TO postgres;

--
-- Name: cleaning_clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cleaning_clients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    name text NOT NULL,
    email text,
    phone text,
    contract_details jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.cleaning_clients OWNER TO postgres;

--
-- Name: cleaning_inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cleaning_inventory (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid,
    item_name text NOT NULL,
    current_quantity numeric(10,2) DEFAULT 0,
    unit text DEFAULT 'liters'::text,
    min_threshold numeric(10,2) DEFAULT 1.0,
    last_restock_at timestamp with time zone,
    catalog_item_id uuid
);


ALTER TABLE public.cleaning_inventory OWNER TO postgres;

--
-- Name: cleaning_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cleaning_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    client_id uuid,
    address text NOT NULL,
    geo_location public.geography(Point,4326),
    geofence_radius_meters integer DEFAULT 50,
    square_meters numeric(10,2),
    access_code text,
    instruction_notes text,
    validation_config jsonb DEFAULT '{"qr_required": true, "gps_required": true, "biometric_required": false}'::jsonb,
    visibility_config jsonb DEFAULT '{"public_status": false, "manager_photos": true}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    qr_code_token text DEFAULT (gen_random_uuid())::text,
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
    location_master_id uuid,
    status text DEFAULT 'active'::text,
    is_cleaning_active boolean DEFAULT true,
    is_maintenance_active boolean DEFAULT false,
    maintenance_notes text,
    ticket_routing_preference text DEFAULT 'auto_exchange'::text,
    preferred_contractor_id uuid,
    place_id text,
    serwis_notes text,
    require_gps_validation_serwis boolean DEFAULT false,
    issue_qr_token uuid DEFAULT gen_random_uuid(),
    is_active_in_serwis boolean DEFAULT true,
    serwis_contacts jsonb DEFAULT '[]'::jsonb,
    admin_contacts jsonb DEFAULT '[]'::jsonb,
    billing_details text,
    access_codes text,
    is_admin_active boolean DEFAULT false,
    admin_compliance_score integer DEFAULT 100,
    name text,
    board_portal_token uuid DEFAULT gen_random_uuid() NOT NULL,
    public_report_token uuid DEFAULT gen_random_uuid() NOT NULL,
    c_kob_building_id text,
    community_id uuid,
    CONSTRAINT cleaning_locations_status_check CHECK ((status = ANY (ARRAY['active'::text, 'archived'::text, 'suspended'::text])))
);


ALTER TABLE public.cleaning_locations OWNER TO postgres;

--
-- Name: COLUMN cleaning_locations.access_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.access_code IS 'DEPRECATED: użyj communities.access_codes.';

--
-- Name: COLUMN cleaning_locations.coordinator_notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.coordinator_notes IS 'Notes from coordinator regarding the cleaning location. Separate from instruction_notes which are for cleaners.';

--
-- Name: COLUMN cleaning_locations.coordinator_can_view_financials; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.coordinator_can_view_financials IS 'Whether coordinator can view financial information for this location';

--
-- Name: COLUMN cleaning_locations.monthly_salary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.monthly_salary IS 'Monthly salary for the location';

--
-- Name: COLUMN cleaning_locations.cleaning_rate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.cleaning_rate IS 'Hourly rate for cleaning services';

--
-- Name: COLUMN cleaning_locations.snow_removal_rate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.snow_removal_rate IS 'Hourly rate for snow removal services';

--
-- Name: COLUMN cleaning_locations.google_place_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.google_place_id IS 'Google Place ID from Places API; used for deduplication and autocomplete';

--
-- Name: COLUMN cleaning_locations.latitude; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.latitude IS 'Latitude (WGS84) for map display';

--
-- Name: COLUMN cleaning_locations.longitude; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.longitude IS 'Longitude (WGS84) for map display';

--
-- Name: COLUMN cleaning_locations.auto_notify_issues; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.auto_notify_issues IS 'If true, issues are automatically sent to client when reported';

--
-- Name: COLUMN cleaning_locations.client_notification_email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.client_notification_email IS 'DEPRECATED: e-mail zarządu w communities.board_email.';

--
-- Name: COLUMN cleaning_locations.is_cleaning_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.is_cleaning_active IS 'Określa czy budynek jest obsługiwany przez moduł DOMIO Cleaning';

--
-- Name: COLUMN cleaning_locations.is_maintenance_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.is_maintenance_active IS 'Określa czy budynek jest obsługiwany przez moduł DOMIO Serwis';

--
-- Name: COLUMN cleaning_locations.maintenance_notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.maintenance_notes IS 'Uwagi koordynatora/właściciela dla modułu Serwis (nie widoczne w sprzątaniu)';

--
-- Name: COLUMN cleaning_locations.ticket_routing_preference; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.ticket_routing_preference IS 'Opcje: auto_exchange (na gielde), requires_approval (wymaga akceptacji), specific_contractor (konkretna firma)';

--
-- Name: COLUMN cleaning_locations.place_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.place_id IS 'ID z Google Maps, służy do zapobiegania dublowaniu budynków';

--
-- Name: COLUMN cleaning_locations.serwis_notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.serwis_notes IS 'Notatki widoczne TYLKO w aplikacji Serwis';

--
-- Name: COLUMN cleaning_locations.require_gps_validation_serwis; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.require_gps_validation_serwis IS 'Flaga: ten budynek wymusza weryfikację GPS od każdego technika';

--
-- Name: COLUMN cleaning_locations.issue_qr_token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.issue_qr_token IS 'Unikalny token do linku w kodzie QR zgłoszenia usterki';

--
-- Name: COLUMN cleaning_locations.is_active_in_serwis; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.is_active_in_serwis IS 'Czy budynek jest obsługiwany przez DOMIO Serwis (pozwala ukryć budynki tylko ze sprzątania)';

--
-- Name: COLUMN cleaning_locations.serwis_contacts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.serwis_contacts IS 'Kontakty prywatne koordynatora serwisu (JSON array)';

--
-- Name: COLUMN cleaning_locations.admin_contacts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.admin_contacts IS 'DEPRECATED: członkowie zarządu w communities.board_members; pole zachowane dla historii.';

--
-- Name: COLUMN cleaning_locations.billing_details; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.billing_details IS 'DEPRECATED: przenieś do communities.financial_details / billingDetailsLegacy.';

--
-- Name: COLUMN cleaning_locations.access_codes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.access_codes IS 'DEPRECATED (tekst): użyj communities.access_codes (JSON).';

--
-- Name: COLUMN cleaning_locations.board_portal_token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.board_portal_token IS 'Opaque UUID for /portal/board/:token (guest board portal). Rotate on leak.';

--
-- Name: COLUMN cleaning_locations.public_report_token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_locations.public_report_token IS 'Opaque UUID for /portal/report/:token (resident issue form). Rotate on leak.';

--
-- Name: cleaning_staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cleaning_staff (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid,
    full_name text NOT NULL,
    phone text,
    internal_id text,
    pin text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    notes text,
    emergency_contact text,
    emergency_phone text,
    status text DEFAULT 'active'::text,
    employment_type text,
    contact_email text
);


ALTER TABLE public.cleaning_staff OWNER TO postgres;

--
-- Name: COLUMN cleaning_staff.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_staff.status IS 'Worker status: active, inactive, on_leave, etc.';

--
-- Name: COLUMN cleaning_staff.employment_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_staff.employment_type IS 'Employment type: full_time, part_time, contract, etc.';

--
-- Name: COLUMN cleaning_staff.contact_email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_staff.contact_email IS 'Contact email for HR/communication; may differ from auth email in profiles.';

--
-- Name: cleaning_tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cleaning_tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid,
    assigned_staff_id uuid,
    status public.task_status DEFAULT 'pending'::public.task_status,
    priority public.priority_level DEFAULT 'medium'::public.priority_level,
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
    task_type public.task_type DEFAULT 'sop_standard'::public.task_type NOT NULL,
    applied_hourly_rate numeric(10,2),
    total_cost numeric(10,2),
    is_paid boolean DEFAULT false,
    CONSTRAINT cleaning_tasks_task_type_check CHECK ((task_type = ANY (ARRAY['sop_standard'::public.task_type, 'coordinator_single'::public.task_type, 'long_term'::public.task_type, 'employee_extra'::public.task_type])))
);


ALTER TABLE public.cleaning_tasks OWNER TO postgres;

--
-- Name: TABLE cleaning_tasks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.cleaning_tasks IS 'Cleaning tasks table. When generating daily checklists, the system must consider task_type:
   - sop_standard: Generated based on frequency (daily, weekly, etc.) from SOP templates
   - coordinator_single: Always included when scheduled_at matches the target date (one-time, high priority)
   - long_term: Generated less frequently (e.g., quarterly), included only on specific dates
   - employee_extra: Generated from checklist JSONB when tasks are added by staff during work';

--
-- Name: COLUMN cleaning_tasks.task_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cleaning_tasks.task_type IS 'Task type determines how tasks are generated and prioritized in daily checklists. 
   sop_standard: Standard recurring tasks from SOP templates (default).
   coordinator_single: One-time tasks created by coordinator (high priority).
   long_term: Long-term maintenance tasks (e.g., quarterly cleaning, low priority).
   employee_extra: Extra tasks added by cleaning staff during work (already supported in code).';

--
-- Name: communities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.communities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    name text NOT NULL,
    nip text,
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    legal_name text,
    regon text,
    board_email text,
    financial_details jsonb DEFAULT '{}'::jsonb NOT NULL,
    access_codes jsonb DEFAULT '{}'::jsonb NOT NULL,
    operational_notes jsonb DEFAULT '{}'::jsonb NOT NULL,
    board_members jsonb DEFAULT '[]'::jsonb NOT NULL,
    CONSTRAINT communities_access_codes_object_check CHECK ((jsonb_typeof(access_codes) = 'object'::text)),
    CONSTRAINT communities_board_members_array_check CHECK ((jsonb_typeof(board_members) = 'array'::text)),
    CONSTRAINT communities_financial_details_object_check CHECK ((jsonb_typeof(financial_details) = 'object'::text)),
    CONSTRAINT communities_operational_notes_object_check CHECK ((jsonb_typeof(operational_notes) = 'object'::text))
);


ALTER TABLE public.communities OWNER TO postgres;

--
-- Name: COLUMN communities.legal_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.communities.legal_name IS 'Pełna nazwa bytu prawnego wspólnoty (z formal.communityName / name).';

--
-- Name: COLUMN communities.regon; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.communities.regon IS 'REGON wspólnoty.';

--
-- Name: COLUMN communities.board_email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.communities.board_email IS 'E-mail zarządu (admin_data.boardEmail / fallback client_notification_email).';

--
-- Name: COLUMN communities.financial_details; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.communities.financial_details IS 'Stawki i rozliczenia (JSON).';

--
-- Name: COLUMN communities.access_codes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.communities.access_codes IS 'Kody dostępu (JSON: intercom, keypad, gate, legacy*).';

--
-- Name: COLUMN communities.operational_notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.communities.operational_notes IS 'Uwagi: administration, cleaning, serwis; opcjonalnie adminContactsLegacy.';

--
-- Name: COLUMN communities.board_members; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.communities.board_members IS 'Członkowie zarządu (JSON array).';

--
-- Name: community_board; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_board (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid NOT NULL,
    author_id uuid NOT NULL,
    post_type public.community_post_type NOT NULL,
    status public.community_post_status DEFAULT 'active'::public.community_post_status NOT NULL,
    title character varying(150) NOT NULL,
    content text NOT NULL,
    price numeric(10,2),
    is_free boolean DEFAULT false NOT NULL,
    event_date timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_free_price CHECK ((((is_free = true) AND ((price IS NULL) OR (price = (0)::numeric))) OR (is_free = false))),
    CONSTRAINT community_board_price_check CHECK ((price >= (0)::numeric))
);


ALTER TABLE public.community_board OWNER TO postgres;

--
-- Name: community_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_comments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    post_id uuid NOT NULL,
    author_id uuid NOT NULL,
    org_id uuid NOT NULL,
    content text NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.community_comments OWNER TO postgres;

--
-- Name: e_board_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.e_board_messages (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid,
    title text NOT NULL,
    content text NOT NULL,
    display_from timestamp with time zone DEFAULT now(),
    display_until timestamp with time zone,
    audience text DEFAULT 'all'::text,
    is_active boolean DEFAULT true,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    community_id uuid,
    msg_type public.eboard_msg_type DEFAULT 'official'::public.eboard_msg_type NOT NULL,
    status public.eboard_msg_status DEFAULT 'published'::public.eboard_msg_status NOT NULL,
    author_id uuid,
    valid_until timestamp with time zone
);


ALTER TABLE public.e_board_messages OWNER TO postgres;

--
-- Name: fuel_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fuel_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    vehicle_id uuid NOT NULL,
    driver_id uuid NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    cost numeric NOT NULL,
    liters numeric NOT NULL,
    fuel_type text NOT NULL,
    current_mileage integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.fuel_logs OWNER TO postgres;

--
-- Name: inspection_campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inspection_campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid NOT NULL,
    title text NOT NULL,
    category text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    vendor_id uuid,
    e_board_message_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    start_time time without time zone,
    end_time time without time zone
);


ALTER TABLE public.inspection_campaigns OWNER TO postgres;

--
-- Name: inspections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inspections (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    location_id uuid,
    title text NOT NULL,
    source text DEFAULT 'domio_internal'::text,
    external_id text,
    last_date date,
    next_due_date date,
    status text DEFAULT 'active'::text,
    attachments jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.inspections OWNER TO postgres;

--
-- Name: inspections_hybrid; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inspections_hybrid (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid,
    title text NOT NULL,
    source text DEFAULT 'internal'::text,
    external_id text,
    category text NOT NULL,
    last_inspection_date date,
    next_due_date date NOT NULL,
    assigned_vendor_id uuid,
    status text DEFAULT 'pending'::text,
    attachments jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.inspections_hybrid OWNER TO postgres;

--
-- Name: internal_tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.internal_tasks (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid,
    assigned_to uuid,
    title text NOT NULL,
    description text,
    priority text DEFAULT 'medium'::text,
    status text DEFAULT 'todo'::text,
    is_ai_generated boolean DEFAULT false,
    due_date timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    community_id uuid
);


ALTER TABLE public.internal_tasks OWNER TO postgres;

--
-- Name: legal_documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.legal_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    document_type text NOT NULL,
    version text NOT NULL,
    content text NOT NULL,
    is_active boolean DEFAULT false,
    published_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    is_required boolean DEFAULT true,
    CONSTRAINT legal_documents_document_type_check CHECK ((document_type = ANY (ARRAY['terms'::text, 'privacy'::text, 'marketing'::text])))
);


ALTER TABLE public.legal_documents OWNER TO postgres;

--
-- Name: location_access; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_access (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid,
    user_id uuid,
    access_type text DEFAULT 'permanent'::text,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    unit_number text
);


ALTER TABLE public.location_access OWNER TO postgres;

--
-- Name: TABLE location_access; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.location_access IS 'Manages staff access to cleaning locations. Links users (profiles) to locations they can access.';

--
-- Name: COLUMN location_access.unit_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.location_access.unit_number IS 'Optional unit label for the resident (e.g. m. 12, lok. 3).';

--
-- Name: location_holidays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_holidays (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid,
    holiday_date date NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT location_holidays_date_check CHECK ((holiday_date IS NOT NULL)),
    CONSTRAINT location_holidays_org_id_check CHECK ((org_id IS NOT NULL))
);


ALTER TABLE public.location_holidays OWNER TO postgres;

--
-- Name: TABLE location_holidays; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.location_holidays IS 'Holidays and work breaks for locations or entire organizations';

--
-- Name: COLUMN location_holidays.org_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.location_holidays.org_id IS 'Organization ID - required';

--
-- Name: COLUMN location_holidays.location_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.location_holidays.location_id IS 'Location ID - NULL means holiday applies to entire organization';

--
-- Name: COLUMN location_holidays.holiday_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.location_holidays.holiday_date IS 'Date of the holiday/break';

--
-- Name: COLUMN location_holidays.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.location_holidays.description IS 'Optional description (e.g., "Remont", "Święto")';

--
-- Name: location_vendor_routing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_vendor_routing (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid NOT NULL,
    issue_category text NOT NULL,
    vendor_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.location_vendor_routing OWNER TO postgres;

--
-- Name: locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid,
    full_address text NOT NULL,
    city text,
    postal_code text,
    google_place_id text,
    latitude double precision,
    longitude double precision,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.locations OWNER TO postgres;

--
-- Name: material_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid,
    location_id uuid,
    requester_id uuid,
    items jsonb NOT NULL,
    notes text,
    status text DEFAULT 'pending'::text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.material_requests OWNER TO postgres;

--
-- Name: memberships; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.memberships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    org_id uuid NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    permissions jsonb DEFAULT '{"can_view_finances": false, "can_edit_schedules": true, "can_view_personnel": true, "can_manage_inventory": true, "can_edit_property_settings": false}'::jsonb,
    can_view_billing boolean DEFAULT false,
    is_active boolean DEFAULT true,
    specializations text[] DEFAULT '{}'::text[],
    require_gps_validation boolean DEFAULT false,
    can_view_financials boolean DEFAULT false,
    CONSTRAINT memberships_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'coordinator'::text, 'cleaner'::text])))
);


ALTER TABLE public.memberships OWNER TO postgres;

--
-- Name: COLUMN memberships.permissions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.memberships.permissions IS 'Dynamiczne uprawnienia dla roli koordynatora i właściciela';

--
-- Name: COLUMN memberships.can_view_billing; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.memberships.can_view_billing IS 'Koordynator może widzieć zakładkę Rozliczenia i Raporty';

--
-- Name: COLUMN memberships.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.memberships.is_active IS 'Czy pracownik pracuje/jest dostępny: true = tak, false = zwolniony/urlop';

--
-- Name: COLUMN memberships.specializations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.memberships.specializations IS 'Lista specjalizacji technika, np. ["Hydrauliczna", "Elektryczna"]';

--
-- Name: COLUMN memberships.require_gps_validation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.memberships.require_gps_validation IS 'Czy pracownik musi mieć zgodność GPS z adresem, aby kliknąć Rozpocznij';

--
-- Name: COLUMN memberships.can_view_financials; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.memberships.can_view_financials IS 'Czy ten pracownik (np. koordynator) ma dostęp do zakładki Rozliczenia i Raporty';

--
-- Name: notification_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type text NOT NULL,
    subject text NOT NULL,
    body_template text NOT NULL,
    days_before integer DEFAULT 7 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    org_id uuid,
    send_to text DEFAULT 'both'::text NOT NULL,
    CONSTRAINT notification_templates_send_to_check CHECK ((send_to = ANY (ARRAY['driver'::text, 'admin'::text, 'both'::text])))
);


ALTER TABLE public.notification_templates OWNER TO postgres;

--
-- Name: offer_interactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offer_interactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    offer_id uuid NOT NULL,
    user_id uuid NOT NULL,
    location_id uuid,
    interaction_type text NOT NULL,
    captured_value text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.offer_interactions OWNER TO postgres;

--
-- Name: org_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    app_id uuid NOT NULL,
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone
);


ALTER TABLE public.org_subscriptions OWNER TO postgres;

--
-- Name: organizations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.organizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    owner_id uuid,
    tenant_id text,
    database_url text,
    global_coordinator_view_financials boolean DEFAULT false,
    is_snow_season boolean DEFAULT false,
    task_generation_days integer DEFAULT 15,
    support_email text,
    nip text,
    address text,
    city text,
    postal_code text
);


ALTER TABLE public.organizations OWNER TO postgres;

--
-- Name: COLUMN organizations.tenant_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.tenant_id IS 'Unique identifier for tenant/subscriber. Used for database routing in multi-tenant architecture.';

--
-- Name: COLUMN organizations.database_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.database_url IS 'Connection string to tenant''s dedicated database instance. Format: postgresql://user:password@host:port/database';

--
-- Name: COLUMN organizations.global_coordinator_view_financials; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.global_coordinator_view_financials IS 'Global setting: whether coordinators can view financial information across all locations';

--
-- Name: COLUMN organizations.is_snow_season; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.is_snow_season IS 'Global setting: when true, snow removal module is visible for workers';

--
-- Name: COLUMN organizations.task_generation_days; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.task_generation_days IS 'Number of days ahead to generate SOP tasks (1-90). Default 15.';

--
-- Name: COLUMN organizations.nip; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.organizations.nip IS 'Tax ID (NIP), optional';

--
-- Name: page_content; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.page_content (
    content_key text NOT NULL,
    section_name text NOT NULL,
    description text NOT NULL,
    content_value text DEFAULT ''::text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.page_content OWNER TO postgres;

--
-- Name: partner_offers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner_offers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    vendor_id uuid NOT NULL,
    location_id uuid,
    title character varying(150) NOT NULL,
    description text NOT NULL,
    promo_code character varying(50),
    redirect_url text,
    image_url text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    action_type text DEFAULT 'url'::text,
    action_value text,
    billing_model text DEFAULT 'subscription'::text,
    target_locations uuid[] DEFAULT '{}'::uuid[],
    icon_emoji text,
    bg_color text,
    promote_on_board boolean DEFAULT false,
    CONSTRAINT valid_redirect_url CHECK (((redirect_url IS NULL) OR (redirect_url ~* '^https?://.*'::text)))
);


ALTER TABLE public.partner_offers OWNER TO postgres;

--
-- Name: pricing_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pricing_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    app_id uuid NOT NULL,
    name text NOT NULL,
    price_monthly numeric(12,2) DEFAULT 0 NOT NULL,
    price_yearly numeric(12,2) DEFAULT 0 NOT NULL,
    features jsonb DEFAULT '[]'::jsonb NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    max_users integer,
    max_locations integer,
    max_storage_gb integer,
    has_ai_features boolean DEFAULT false
);


ALTER TABLE public.pricing_plans OWNER TO postgres;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

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
    fleet_role public.fleet_role,
    contact_email text,
    platform_role text DEFAULT 'user'::text,
    marketing_version text,
    created_at timestamp with time zone DEFAULT now(),
    last_login_at timestamp with time zone,
    last_active_location_access_id uuid
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: COLUMN profiles.terms_version; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.terms_version IS 'Wersja regulaminu zaakceptowana przez użytkownika podczas rejestracji';

--
-- Name: COLUMN profiles.preferences; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.preferences IS 'User preferences stored as JSON (theme, language, etc.)';

--
-- Name: COLUMN profiles.emergency_contact; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.emergency_contact IS 'Emergency contact information stored as JSON (name, phone, relationship)';

--
-- Name: COLUMN profiles.internal_notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.internal_notes IS 'Internal notes about the worker';

--
-- Name: COLUMN profiles.base_hourly_rate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.base_hourly_rate IS 'Base hourly rate for the worker';

--
-- Name: COLUMN profiles.snow_hourly_rate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.snow_hourly_rate IS 'Hourly rate for snow removal services';

--
-- Name: COLUMN profiles.account_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.account_type IS 'Account type: hub or simplified';

--
-- Name: COLUMN profiles.fixed_salary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.fixed_salary IS 'Fixed monthly salary for the worker';

--
-- Name: COLUMN profiles.contact_email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.contact_email IS 'Rzeczywisty adres e-mail pracownika (szczególnie przydatny dla kont uproszczonych)';

--
-- Name: COLUMN profiles.last_active_location_access_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.last_active_location_access_id IS 'Last location_access row the resident selected in DOMIO Home (multi-unit / multi-building).';

--
-- Name: promo_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.promo_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    discount_percent numeric(5,2),
    discount_amount numeric(12,2),
    max_uses integer,
    used_count integer DEFAULT 0 NOT NULL,
    valid_until date,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.promo_codes OWNER TO postgres;

--
-- Name: property_checklists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_checklists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid,
    name text NOT NULL,
    requires_photo boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    section_id uuid,
    frequency text DEFAULT 'Codziennie'::text,
    frequency_config jsonb DEFAULT '{"type": "daily"}'::jsonb,
    is_active boolean DEFAULT true,
    org_id uuid,
    baseline_date date DEFAULT CURRENT_DATE
);


ALTER TABLE public.property_checklists OWNER TO postgres;

--
-- Name: COLUMN property_checklists.frequency_config; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_checklists.frequency_config IS 'Technical frequency configuration (JSONB). Structure: { "type": "daily|work_days|specific_days|weekly|biweekly|monthly|quarterly|custom", "days": [0-6] (for specific_days), "text": "..." (for custom) }';

--
-- Name: COLUMN property_checklists.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_checklists.is_active IS 'Whether the recurring task is active and should be generated in schedule';

--
-- Name: property_contracts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_contracts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    company_id uuid NOT NULL,
    type public.property_contract_type NOT NULL,
    contract_number text NOT NULL,
    net_value numeric(12,2) NOT NULL,
    currency text DEFAULT 'PLN'::text NOT NULL,
    start_date date NOT NULL,
    end_date date,
    notice_period_months integer,
    document_url text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    vat_rate numeric(5,2) DEFAULT 23.00,
    gross_value numeric(12,2) DEFAULT 0.00,
    custom_type_name text,
    community_id uuid,
    CONSTRAINT property_contracts_contract_number_check CHECK ((length(TRIM(BOTH FROM contract_number)) > 0)),
    CONSTRAINT property_contracts_currency_check CHECK ((length(TRIM(BOTH FROM currency)) > 0)),
    CONSTRAINT property_contracts_end_after_start CHECK (((end_date IS NULL) OR (end_date >= start_date))),
    CONSTRAINT property_contracts_notice_period_months_check CHECK (((notice_period_months IS NULL) OR (notice_period_months >= 0)))
);


ALTER TABLE public.property_contracts OWNER TO postgres;

--
-- Name: TABLE property_contracts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.property_contracts IS 'At most one contract per location; company references global companies.';

--
-- Name: COLUMN property_contracts.document_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_contracts.document_url IS 'Scanned contract / Storage URL; empty until uploaded.';

--
-- Name: COLUMN property_contracts.custom_type_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_contracts.custom_type_name IS 'Wypełniane tylko gdy type = "other"';

--
-- Name: property_inspections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_inspections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    company_id uuid NOT NULL,
    type public.inspection_type NOT NULL,
    status public.inspection_status DEFAULT 'positive'::public.inspection_status NOT NULL,
    execution_date date NOT NULL,
    valid_until date NOT NULL,
    protocol_number text,
    inspector_name text,
    notes text,
    document_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    c_kob_id text,
    c_kob_sync_status public.sync_status DEFAULT 'not_synced'::public.sync_status NOT NULL,
    c_kob_error_log text,
    c_kob_last_sync_at timestamp with time zone,
    CONSTRAINT valid_dates_check CHECK ((valid_until >= execution_date))
);


ALTER TABLE public.property_inspections OWNER TO postgres;

--
-- Name: property_issues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_issues (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid,
    location_id uuid,
    reporter_id uuid,
    description text,
    photo_url text,
    status public.issue_status_enum DEFAULT 'new'::public.issue_status_enum,
    created_at timestamp with time zone DEFAULT now(),
    notification_status text DEFAULT 'pending'::text,
    reporter_name text,
    reporter_phone text,
    reporter_type text DEFAULT 'tenant'::text,
    priority public.issue_priority_enum DEFAULT 'medium'::public.issue_priority_enum,
    assigned_staff_id uuid,
    is_public_broadcast boolean DEFAULT false,
    claimed_by_org_id uuid,
    resolved_at timestamp with time zone,
    waiting_reason text,
    estimated_resolution_date date,
    is_transfer_requested boolean DEFAULT false,
    transfer_reason text,
    internal_comments jsonb DEFAULT '[]'::jsonb,
    started_at timestamp with time zone,
    resolution_notes text,
    materials_used jsonb DEFAULT '[]'::jsonb,
    total_material_cost numeric DEFAULT 0,
    photos_before text[] DEFAULT '{}'::text[],
    photos_after text[] DEFAULT '{}'::text[],
    category text,
    reporter_email text,
    labor_cost numeric DEFAULT 0,
    is_invoiced boolean DEFAULT false,
    scheduled_at timestamp with time zone,
    estimated_hours numeric,
    require_gps_validation boolean DEFAULT false,
    labor_hours numeric,
    client_signature text,
    signed_by text,
    source text DEFAULT 'manual'::text,
    delegated_vendor_id uuid,
    is_ai_draft boolean DEFAULT false,
    ai_confidence_score numeric
);


ALTER TABLE public.property_issues OWNER TO postgres;

--
-- Name: COLUMN property_issues.notification_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.notification_status IS 'Status of notification: pending (awaiting approval) or sent (notified to client)';

--
-- Name: COLUMN property_issues.reporter_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.reporter_name IS 'Imię osoby zgłaszającej usterkę (z publicznego formularza QR)';

--
-- Name: COLUMN property_issues.reporter_phone; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.reporter_phone IS 'Telefon osoby zgłaszającej usterkę (z publicznego formularza QR)';

--
-- Name: COLUMN property_issues.reporter_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.reporter_type IS 'administrator = from cleaning_clients, tenant = private person';

--
-- Name: COLUMN property_issues.priority; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.priority IS 'standard or krytyczny (24h)';

--
-- Name: COLUMN property_issues.assigned_staff_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.assigned_staff_id IS 'Staff assigned to fix (null = internal exchange)';

--
-- Name: COLUMN property_issues.is_public_broadcast; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.is_public_broadcast IS 'If true, shared in ecosystem order exchange';

--
-- Name: COLUMN property_issues.resolved_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.resolved_at IS 'Data i czas faktycznego zakończenia/rozwiązania usterki';

--
-- Name: COLUMN property_issues.started_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.started_at IS 'Czas kliknięcia Rozpocznij';

--
-- Name: COLUMN property_issues.materials_used; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.materials_used IS 'Tablica obiektów: {name, quantity, unit_cost, total_cost}';

--
-- Name: COLUMN property_issues.category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.category IS 'Hydrauliczna | Elektryczna | Ślusarska | Ogólnobudowlana | Inna';

--
-- Name: COLUMN property_issues.reporter_email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.reporter_email IS 'Email osoby zgłaszającej usterkę';

--
-- Name: COLUMN property_issues.labor_cost; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.labor_cost IS 'Całkowity koszt robocizny w PLN wpisany przy zamykaniu zlecenia';

--
-- Name: COLUMN property_issues.is_invoiced; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.is_invoiced IS 'Flaga czy zakończona usterka została już zafakturowana/rozliczona z administratorem';

--
-- Name: COLUMN property_issues.scheduled_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.scheduled_at IS 'Zaplanowany termin realizacji zlecenia (Data i czas)';

--
-- Name: COLUMN property_issues.estimated_hours; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.estimated_hours IS 'Szacowany czas pracy (RBH) podany przez dyspozytora';

--
-- Name: COLUMN property_issues.require_gps_validation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.require_gps_validation IS 'Wymuszenie GPS tylko dla tego konkretnego zlecenia (nadpisuje ustawienia budynku/technika)';

--
-- Name: COLUMN property_issues.labor_hours; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.labor_hours IS 'Czas pracy technika w RBH (Roboczogodzinach) podany przy zamykaniu zlecenia';

--
-- Name: COLUMN property_issues.client_signature; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.client_signature IS 'Podpis klienta złożony na telefonie technika (np. w formacie base64 lub link)';

--
-- Name: COLUMN property_issues.signed_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_issues.signed_by IS 'Imię i nazwisko osoby, która fizycznie podpisała protokół';

--
-- Name: property_policies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_policies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    company_id uuid NOT NULL,
    policy_number text NOT NULL,
    coverage_amount numeric(14,2) NOT NULL,
    premium_amount numeric(12,2) DEFAULT 0 NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    document_url text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    policy_scope public.policy_scope_enum DEFAULT 'majątkowe'::public.policy_scope_enum,
    insurer_name text,
    community_id uuid,
    CONSTRAINT property_policies_end_after_start CHECK ((end_date >= start_date)),
    CONSTRAINT property_policies_policy_number_check CHECK ((length(TRIM(BOTH FROM policy_number)) > 0))
);


ALTER TABLE public.property_policies OWNER TO postgres;

--
-- Name: COLUMN property_policies.document_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_policies.document_url IS 'Policy PDF / Storage URL; empty until uploaded.';

--
-- Name: property_sections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_sections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid,
    name text NOT NULL,
    assigned_staff_id uuid,
    allow_cross_access boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true
);


ALTER TABLE public.property_sections OWNER TO postgres;

--
-- Name: COLUMN property_sections.sort_order; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_sections.sort_order IS 'Order in which sections should be displayed. Lower values appear first.';

--
-- Name: COLUMN property_sections.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.property_sections.is_active IS 'Jeśli false, sekcja jest zarchiwizowana (niewidoczna przy nowych zadaniach, ale widoczna w historii).';

--
-- Name: property_tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    title text NOT NULL,
    status public.property_task_status DEFAULT 'todo'::public.property_task_status NOT NULL,
    priority public.property_task_priority DEFAULT 'medium'::public.property_task_priority NOT NULL,
    visibility public.property_task_visibility DEFAULT 'internal_only'::public.property_task_visibility NOT NULL,
    assignee_id uuid,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    community_id uuid,
    CONSTRAINT property_tasks_title_check CHECK ((length(TRIM(BOTH FROM title)) > 0))
);


ALTER TABLE public.property_tasks OWNER TO postgres;

--
-- Name: repair_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.repair_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    vehicle_id uuid NOT NULL,
    description text NOT NULL,
    cost numeric DEFAULT 0 NOT NULL,
    repair_date date DEFAULT CURRENT_DATE NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.repair_logs OWNER TO postgres;

--
-- Name: resident_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resident_configs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    location_id uuid NOT NULL,
    show_cleaning_status boolean DEFAULT true NOT NULL,
    show_service_tracker boolean DEFAULT true NOT NULL,
    enable_community_board boolean DEFAULT false NOT NULL,
    enable_partner_offers boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.resident_configs OWNER TO postgres;

--
-- Name: staff_equipment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_equipment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    org_id uuid NOT NULL,
    type text NOT NULL,
    name text NOT NULL,
    assigned_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT staff_equipment_type_check CHECK ((type = ANY (ARRAY['key'::text, 'card'::text, 'tool'::text, 'other'::text])))
);


ALTER TABLE public.staff_equipment OWNER TO postgres;

--
-- Name: staff_financial_adjustments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_financial_adjustments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    amount numeric NOT NULL,
    reason text,
    adjustment_date date DEFAULT CURRENT_DATE,
    type text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT staff_financial_adjustments_type_check CHECK ((type = ANY (ARRAY['bonus'::text, 'potrącenie'::text, 'korekta_godzin'::text])))
);


ALTER TABLE public.staff_financial_adjustments OWNER TO postgres;

--
-- Name: staff_payouts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_payouts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    org_id uuid NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    total_amount numeric NOT NULL,
    paid_at timestamp with time zone DEFAULT now(),
    paid_by uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT staff_payouts_month_check CHECK (((month >= 1) AND (month <= 12))),
    CONSTRAINT staff_payouts_year_check CHECK (((year >= 2020) AND (year <= 2100)))
);


ALTER TABLE public.staff_payouts OWNER TO postgres;

--
-- Name: staff_rate_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_rate_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    base_hourly_rate numeric(10,2),
    snow_hourly_rate numeric(10,2),
    fixed_salary numeric(10,2),
    changed_at timestamp with time zone DEFAULT now(),
    changed_by uuid
);


ALTER TABLE public.staff_rate_history OWNER TO postgres;

--
-- Name: task_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_comments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid NOT NULL,
    author_id uuid NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT task_comments_content_check CHECK ((length(TRIM(BOTH FROM content)) > 0))
);


ALTER TABLE public.task_comments OWNER TO postgres;

--
-- Name: task_step_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_step_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid,
    user_id uuid,
    step_name text,
    created_at timestamp with time zone DEFAULT now(),
    photo_url text,
    is_extra_task boolean DEFAULT false
);


ALTER TABLE public.task_step_logs OWNER TO postgres;

--
-- Name: TABLE task_step_logs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.task_step_logs IS 'Logi każdego odhaczenia checkboxa w checklistach zadań';

--
-- Name: COLUMN task_step_logs.photo_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.task_step_logs.photo_url IS 'URL zdjęcia związanego z tym logiem czynności (z Supabase Storage bucket task-photos)';

--
-- Name: unit_inspection_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unit_inspection_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    unit_number text NOT NULL,
    status public.unit_inspection_status DEFAULT 'pending'::public.unit_inspection_status NOT NULL,
    inspection_date timestamp with time zone,
    notes text,
    photo_url text,
    signature_url text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.unit_inspection_records OWNER TO postgres;

--
-- Name: user_app_access; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.user_app_access WITH (security_invoker='true') AS
 SELECT DISTINCT m.user_id,
    os.app_id,
    a.name AS app_name,
    a.domain_url AS app_domain_url,
    a.api_url AS app_api_url,
    m.org_id,
    o.name AS org_name,
    os.status AS subscription_status
   FROM (((public.memberships m
     JOIN public.org_subscriptions os ON ((os.org_id = m.org_id)))
     JOIN public.applications a ON ((a.id = os.app_id)))
     JOIN public.organizations o ON ((o.id = m.org_id)))
  WHERE ((os.status = 'active'::text) AND (a.is_active = true));


ALTER VIEW public.user_app_access OWNER TO postgres;

--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    model text NOT NULL,
    year integer NOT NULL,
    vin text NOT NULL,
    reg_no text NOT NULL,
    mileage integer DEFAULT 0 NOT NULL,
    tire_info text,
    insurance_expiry date NOT NULL,
    next_inspection date NOT NULL,
    tire_change_date date,
    assigned_driver_id uuid,
    policy_url text,
    reg_doc_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.vehicles OWNER TO postgres;

--
-- Name: v_active_notifications; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_active_notifications AS
 SELECT v.id AS vehicle_id,
    v.org_id,
    v.reg_no,
    v.model,
    p.full_name AS driver_name,
    p.email AS driver_email,
    nt.type AS alert_type,
    nt.subject,
    nt.body_template,
        CASE
            WHEN (nt.type = 'insurance'::text) THEN v.insurance_expiry
            WHEN (nt.type = 'inspection'::text) THEN v.next_inspection
            WHEN (nt.type = 'tires'::text) THEN v.tire_change_date
            ELSE NULL::date
        END AS target_date
   FROM ((public.vehicles v
     LEFT JOIN public.profiles p ON ((v.assigned_driver_id = p.id)))
     CROSS JOIN public.notification_templates nt)
  WHERE (((nt.type = 'inspection'::text) AND (v.next_inspection = (CURRENT_DATE + ((nt.days_before || ' days'::text))::interval))) OR ((nt.type = 'insurance'::text) AND (v.insurance_expiry = (CURRENT_DATE + ((nt.days_before || ' days'::text))::interval))) OR ((nt.type = 'tires'::text) AND (v.tire_change_date = (CURRENT_DATE + ((nt.days_before || ' days'::text))::interval))));


ALTER VIEW public.v_active_notifications OWNER TO postgres;

--
-- Name: v_upcoming_deadlines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_upcoming_deadlines AS
 SELECT vehicles.id AS vehicle_id,
    vehicles.org_id,
    vehicles.reg_no,
    vehicles.model,
    'Przegląd'::text AS type,
    vehicles.next_inspection AS target_date,
    (vehicles.next_inspection - CURRENT_DATE) AS days_left
   FROM public.vehicles
UNION ALL
 SELECT vehicles.id AS vehicle_id,
    vehicles.org_id,
    vehicles.reg_no,
    vehicles.model,
    'Ubezpieczenie'::text AS type,
    vehicles.insurance_expiry AS target_date,
    (vehicles.insurance_expiry - CURRENT_DATE) AS days_left
   FROM public.vehicles;


ALTER VIEW public.v_upcoming_deadlines OWNER TO postgres;

--
-- Name: vendor_partners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendor_partners (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    org_id uuid NOT NULL,
    name text NOT NULL,
    service_type text NOT NULL,
    contact_email text,
    contact_phone text,
    has_system_access boolean DEFAULT false,
    status text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.vendor_partners OWNER TO postgres;

--
-- Name: admin_contracts admin_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_contracts
    ADD CONSTRAINT admin_contracts_pkey PRIMARY KEY (id);

--
-- Name: applications applications_domain_url_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_domain_url_key UNIQUE (domain_url);

--
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);

--
-- Name: cleaning_catalog cleaning_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_catalog
    ADD CONSTRAINT cleaning_catalog_pkey PRIMARY KEY (id);

--
-- Name: cleaning_clients cleaning_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_clients
    ADD CONSTRAINT cleaning_clients_pkey PRIMARY KEY (id);

--
-- Name: cleaning_inventory cleaning_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_inventory
    ADD CONSTRAINT cleaning_inventory_pkey PRIMARY KEY (id);

--
-- Name: cleaning_locations cleaning_locations_c_kob_building_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_locations
    ADD CONSTRAINT cleaning_locations_c_kob_building_id_key UNIQUE (c_kob_building_id);

--
-- Name: cleaning_locations cleaning_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_locations
    ADD CONSTRAINT cleaning_locations_pkey PRIMARY KEY (id);

--
-- Name: cleaning_locations cleaning_locations_qr_code_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_locations
    ADD CONSTRAINT cleaning_locations_qr_code_token_key UNIQUE (qr_code_token);

--
-- Name: cleaning_staff cleaning_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_staff
    ADD CONSTRAINT cleaning_staff_pkey PRIMARY KEY (id);

--
-- Name: cleaning_tasks cleaning_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_tasks
    ADD CONSTRAINT cleaning_tasks_pkey PRIMARY KEY (id);

--
-- Name: communities communities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.communities
    ADD CONSTRAINT communities_pkey PRIMARY KEY (id);

--
-- Name: community_board community_board_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_board
    ADD CONSTRAINT community_board_pkey PRIMARY KEY (id);

--
-- Name: community_comments community_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_comments
    ADD CONSTRAINT community_comments_pkey PRIMARY KEY (id);

--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);

--
-- Name: companies companies_tax_id_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_tax_id_org_id_key UNIQUE (tax_id, org_id);

--
-- Name: e_board_messages e_board_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.e_board_messages
    ADD CONSTRAINT e_board_messages_pkey PRIMARY KEY (id);

--
-- Name: fuel_logs fuel_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fuel_logs
    ADD CONSTRAINT fuel_logs_pkey PRIMARY KEY (id);

--
-- Name: inspection_campaigns inspection_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspection_campaigns
    ADD CONSTRAINT inspection_campaigns_pkey PRIMARY KEY (id);

--
-- Name: inspections_hybrid inspections_hybrid_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspections_hybrid
    ADD CONSTRAINT inspections_hybrid_pkey PRIMARY KEY (id);

--
-- Name: inspections inspections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspections
    ADD CONSTRAINT inspections_pkey PRIMARY KEY (id);

--
-- Name: internal_tasks internal_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.internal_tasks
    ADD CONSTRAINT internal_tasks_pkey PRIMARY KEY (id);

--
-- Name: legal_documents legal_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.legal_documents
    ADD CONSTRAINT legal_documents_pkey PRIMARY KEY (id);

--
-- Name: location_access location_access_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_access
    ADD CONSTRAINT location_access_pkey PRIMARY KEY (id);

--
-- Name: location_holidays location_holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_holidays
    ADD CONSTRAINT location_holidays_pkey PRIMARY KEY (id);

--
-- Name: location_holidays location_holidays_unique_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_holidays
    ADD CONSTRAINT location_holidays_unique_date UNIQUE (org_id, location_id, holiday_date);

--
-- Name: location_vendor_routing location_vendor_routing_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_vendor_routing
    ADD CONSTRAINT location_vendor_routing_pkey PRIMARY KEY (id);

--
-- Name: locations locations_google_place_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_google_place_id_key UNIQUE (google_place_id);

--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);

--
-- Name: material_requests material_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_requests
    ADD CONSTRAINT material_requests_pkey PRIMARY KEY (id);

--
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);

--
-- Name: memberships memberships_user_role_org_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_user_role_org_unique UNIQUE (user_id, org_id, role);

--
-- Name: notification_templates notification_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (id);

--
-- Name: notification_templates notification_templates_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_type_key UNIQUE (type);

--
-- Name: offer_interactions offer_interactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offer_interactions
    ADD CONSTRAINT offer_interactions_pkey PRIMARY KEY (id);

--
-- Name: org_subscriptions org_subscriptions_org_id_app_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_subscriptions
    ADD CONSTRAINT org_subscriptions_org_id_app_id_key UNIQUE (org_id, app_id);

--
-- Name: org_subscriptions org_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_subscriptions
    ADD CONSTRAINT org_subscriptions_pkey PRIMARY KEY (id);

--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);

--
-- Name: organizations organizations_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_slug_key UNIQUE (slug);

--
-- Name: organizations organizations_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_tenant_id_key UNIQUE (tenant_id);

--
-- Name: page_content page_content_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.page_content
    ADD CONSTRAINT page_content_pkey PRIMARY KEY (content_key);

--
-- Name: partner_offers partner_offers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_offers
    ADD CONSTRAINT partner_offers_pkey PRIMARY KEY (id);

--
-- Name: pricing_plans pricing_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pricing_plans
    ADD CONSTRAINT pricing_plans_pkey PRIMARY KEY (id);

--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);

--
-- Name: promo_codes promo_codes_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promo_codes
    ADD CONSTRAINT promo_codes_code_unique UNIQUE (code);

--
-- Name: promo_codes promo_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promo_codes
    ADD CONSTRAINT promo_codes_pkey PRIMARY KEY (id);

--
-- Name: property_checklists property_checklists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_checklists
    ADD CONSTRAINT property_checklists_pkey PRIMARY KEY (id);

--
-- Name: property_contracts property_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_contracts
    ADD CONSTRAINT property_contracts_pkey PRIMARY KEY (id);

--
-- Name: property_inspections property_inspections_c_kob_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_inspections
    ADD CONSTRAINT property_inspections_c_kob_id_key UNIQUE (c_kob_id);

--
-- Name: property_inspections property_inspections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_inspections
    ADD CONSTRAINT property_inspections_pkey PRIMARY KEY (id);

--
-- Name: property_issues property_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_issues
    ADD CONSTRAINT property_issues_pkey PRIMARY KEY (id);

--
-- Name: property_policies property_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_policies
    ADD CONSTRAINT property_policies_pkey PRIMARY KEY (id);

--
-- Name: property_sections property_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_sections
    ADD CONSTRAINT property_sections_pkey PRIMARY KEY (id);

--
-- Name: property_tasks property_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_tasks
    ADD CONSTRAINT property_tasks_pkey PRIMARY KEY (id);

--
-- Name: repair_logs repair_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repair_logs
    ADD CONSTRAINT repair_logs_pkey PRIMARY KEY (id);

--
-- Name: resident_configs resident_configs_location_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resident_configs
    ADD CONSTRAINT resident_configs_location_id_key UNIQUE (location_id);

--
-- Name: resident_configs resident_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resident_configs
    ADD CONSTRAINT resident_configs_pkey PRIMARY KEY (id);

--
-- Name: staff_equipment staff_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_equipment
    ADD CONSTRAINT staff_equipment_pkey PRIMARY KEY (id);

--
-- Name: staff_financial_adjustments staff_financial_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_financial_adjustments
    ADD CONSTRAINT staff_financial_adjustments_pkey PRIMARY KEY (id);

--
-- Name: staff_payouts staff_payouts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payouts
    ADD CONSTRAINT staff_payouts_pkey PRIMARY KEY (id);

--
-- Name: staff_payouts staff_payouts_unique_month_year; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payouts
    ADD CONSTRAINT staff_payouts_unique_month_year UNIQUE (staff_id, org_id, month, year);

--
-- Name: staff_rate_history staff_rate_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_rate_history
    ADD CONSTRAINT staff_rate_history_pkey PRIMARY KEY (id);

--
-- Name: task_comments task_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_pkey PRIMARY KEY (id);

--
-- Name: task_execution_logs task_execution_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_execution_logs
    ADD CONSTRAINT task_execution_logs_pkey PRIMARY KEY (id);

--
-- Name: task_step_logs task_step_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_step_logs
    ADD CONSTRAINT task_step_logs_pkey PRIMARY KEY (id);

--
-- Name: location_vendor_routing unique_location_category_routing; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_vendor_routing
    ADD CONSTRAINT unique_location_category_routing UNIQUE (location_id, issue_category);

--
-- Name: unit_inspection_records unique_unit_per_campaign; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit_inspection_records
    ADD CONSTRAINT unique_unit_per_campaign UNIQUE (campaign_id, unit_number);

--
-- Name: unit_inspection_records unit_inspection_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit_inspection_records
    ADD CONSTRAINT unit_inspection_records_pkey PRIMARY KEY (id);

--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);

--
-- Name: vehicles vehicles_reg_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_reg_no_key UNIQUE (reg_no);

--
-- Name: vehicles vehicles_vin_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_vin_key UNIQUE (vin);

--
-- Name: vendor_partners vendor_partners_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_partners
    ADD CONSTRAINT vendor_partners_pkey PRIMARY KEY (id);

--
-- Name: idx_cleaning_catalog_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_catalog_org_id ON public.cleaning_catalog USING btree (org_id);

--
-- Name: idx_cleaning_clients_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_clients_org_id ON public.cleaning_clients USING btree (org_id);

--
-- Name: idx_cleaning_inventory_catalog_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_inventory_catalog_item_id ON public.cleaning_inventory USING btree (catalog_item_id);

--
-- Name: idx_cleaning_inventory_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_inventory_location_id ON public.cleaning_inventory USING btree (location_id);

--
-- Name: idx_cleaning_inventory_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_inventory_org_id ON public.cleaning_inventory USING btree (org_id);

--
-- Name: idx_cleaning_locations_board_portal_token_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_cleaning_locations_board_portal_token_unique ON public.cleaning_locations USING btree (board_portal_token);

--
-- Name: idx_cleaning_locations_client_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_locations_client_id ON public.cleaning_locations USING btree (client_id);

--
-- Name: idx_cleaning_locations_community; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_locations_community ON public.cleaning_locations USING btree (community_id);

--
-- Name: idx_cleaning_locations_org_community_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_locations_org_community_vps ON public.cleaning_locations USING btree (org_id, community_id);

--
-- Name: idx_cleaning_locations_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_locations_org_id ON public.cleaning_locations USING btree (org_id);

--
-- Name: idx_cleaning_locations_org_place_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_cleaning_locations_org_place_unique ON public.cleaning_locations USING btree (org_id, google_place_id) WHERE (google_place_id IS NOT NULL);

--
-- Name: idx_cleaning_locations_public_report_token_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_cleaning_locations_public_report_token_unique ON public.cleaning_locations USING btree (public_report_token);

--
-- Name: idx_cleaning_locations_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_locations_status ON public.cleaning_locations USING btree (status);

--
-- Name: idx_cleaning_staff_org_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_staff_org_vps ON public.cleaning_staff USING btree (org_id);

--
-- Name: idx_cleaning_tasks_actual_performer_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_tasks_actual_performer_vps ON public.cleaning_tasks USING btree (actual_performer_id);

--
-- Name: idx_cleaning_tasks_assigned_staff_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_tasks_assigned_staff_id ON public.cleaning_tasks USING btree (assigned_staff_id);

--
-- Name: idx_cleaning_tasks_assigned_staff_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_tasks_assigned_staff_location ON public.cleaning_tasks USING btree (assigned_staff_id, location_id) WHERE ((assigned_staff_id IS NOT NULL) AND (location_id IS NOT NULL));

--
-- Name: idx_cleaning_tasks_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_tasks_location_id ON public.cleaning_tasks USING btree (location_id);

--
-- Name: idx_cleaning_tasks_org_assigned_sched_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_tasks_org_assigned_sched_vps ON public.cleaning_tasks USING btree (org_id, assigned_staff_id, scheduled_at);

--
-- Name: idx_cleaning_tasks_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_tasks_org_id ON public.cleaning_tasks USING btree (org_id);

--
-- Name: idx_cleaning_tasks_status_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_tasks_status_at ON public.cleaning_tasks USING btree (status, scheduled_at, location_id);

--
-- Name: idx_cleaning_tasks_task_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cleaning_tasks_task_type ON public.cleaning_tasks USING btree (task_type);

--
-- Name: idx_comments_post_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comments_post_id ON public.community_comments USING btree (post_id) WHERE (is_deleted = false);

--
-- Name: idx_communities_org; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_communities_org ON public.communities USING btree (org_id);

--
-- Name: idx_community_board_author; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_community_board_author ON public.community_board USING btree (author_id);

--
-- Name: idx_community_board_location_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_community_board_location_active ON public.community_board USING btree (location_id, status) WHERE (status = 'active'::public.community_post_status);

--
-- Name: idx_contracts_community; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contracts_community ON public.property_contracts USING btree (community_id);

--
-- Name: idx_contracts_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contracts_location ON public.admin_contracts USING btree (location_id);

--
-- Name: idx_domio_memberships_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_domio_memberships_lookup ON public.memberships USING btree (user_id, org_id);

--
-- Name: idx_domio_tasks_org_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_domio_tasks_org_user ON public.cleaning_tasks USING btree (org_id);

--
-- Name: idx_e_board_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_e_board_active ON public.e_board_messages USING btree (location_id, is_active);

--
-- Name: idx_eboard_community; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_eboard_community ON public.e_board_messages USING btree (community_id);

--
-- Name: idx_eboard_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_eboard_location ON public.e_board_messages USING btree (location_id);

--
-- Name: idx_eboard_org; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_eboard_org ON public.e_board_messages USING btree (org_id);

--
-- Name: idx_fuel_logs_driver_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fuel_logs_driver_id ON public.fuel_logs USING btree (driver_id);

--
-- Name: idx_fuel_logs_vehicle_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fuel_logs_vehicle_id ON public.fuel_logs USING btree (vehicle_id);

--
-- Name: idx_inspection_campaigns_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inspection_campaigns_location ON public.inspection_campaigns USING btree (location_id);

--
-- Name: idx_inspections_due_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inspections_due_date ON public.inspections_hybrid USING btree (next_due_date);

--
-- Name: idx_internal_tasks_community; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_internal_tasks_community ON public.internal_tasks USING btree (community_id);

--
-- Name: idx_location_access_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_access_location_id ON public.location_access USING btree (location_id);

--
-- Name: idx_location_access_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_access_user_id ON public.location_access USING btree (user_id);

--
-- Name: idx_location_access_user_location_type_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_access_user_location_type_vps ON public.location_access USING btree (user_id, location_id, access_type);

--
-- Name: idx_location_holidays_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_holidays_date ON public.location_holidays USING btree (holiday_date);

--
-- Name: idx_location_holidays_global_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_location_holidays_global_unique ON public.location_holidays USING btree (org_id, holiday_date) WHERE (location_id IS NULL);

--
-- Name: idx_location_holidays_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_holidays_location_id ON public.location_holidays USING btree (location_id);

--
-- Name: idx_location_holidays_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_holidays_org_id ON public.location_holidays USING btree (org_id);

--
-- Name: idx_location_holidays_org_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_holidays_org_location ON public.location_holidays USING btree (org_id, location_id);

--
-- Name: idx_locations_google_place_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_locations_google_place_id ON public.locations USING btree (google_place_id) WHERE (google_place_id IS NOT NULL);

--
-- Name: idx_material_requests_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_material_requests_location_id ON public.material_requests USING btree (location_id);

--
-- Name: idx_material_requests_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_material_requests_org_id ON public.material_requests USING btree (org_id);

--
-- Name: idx_material_requests_requester_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_material_requests_requester_id ON public.material_requests USING btree (requester_id);

--
-- Name: idx_memberships_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_memberships_lookup ON public.memberships USING btree (user_id, org_id, role);

--
-- Name: idx_memberships_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_memberships_org_id ON public.memberships USING btree (org_id);

--
-- Name: idx_memberships_org_user_active_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_memberships_org_user_active_vps ON public.memberships USING btree (org_id, user_id, is_active);

--
-- Name: idx_memberships_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_memberships_user_id ON public.memberships USING btree (user_id);

--
-- Name: idx_notification_templates_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notification_templates_org_id ON public.notification_templates USING btree (org_id);

--
-- Name: idx_organizations_tenant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_organizations_tenant_id ON public.organizations USING btree (tenant_id);

--
-- Name: idx_page_content_section_sort; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_page_content_section_sort ON public.page_content USING btree (section_name, sort_order, content_key);

--
-- Name: idx_partner_offers_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_partner_offers_location ON public.partner_offers USING btree (location_id) WHERE (is_active = true);

--
-- Name: idx_partner_offers_org; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_partner_offers_org ON public.partner_offers USING btree (org_id) WHERE (is_active = true);

--
-- Name: idx_partner_offers_org_active_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_partner_offers_org_active_vps ON public.partner_offers USING btree (org_id, is_active);

--
-- Name: idx_policies_community; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_policies_community ON public.property_policies USING btree (community_id);

--
-- Name: idx_pricing_plans_app_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pricing_plans_app_id ON public.pricing_plans USING btree (app_id);

--
-- Name: idx_profiles_account_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_account_type ON public.profiles USING btree (account_type);

--
-- Name: idx_profiles_preferences; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_preferences ON public.profiles USING gin (preferences);

--
-- Name: idx_property_checklists_loc_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_checklists_loc_active ON public.property_checklists USING btree (location_id, is_active);

--
-- Name: idx_property_checklists_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_checklists_org_id ON public.property_checklists USING btree (org_id);

--
-- Name: idx_property_checklists_section_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_checklists_section_id ON public.property_checklists USING btree (section_id);

--
-- Name: idx_property_contracts_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_contracts_company_id ON public.property_contracts USING btree (company_id);

--
-- Name: idx_property_inspections_ckob_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_inspections_ckob_status ON public.property_inspections USING btree (c_kob_sync_status);

--
-- Name: idx_property_inspections_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_inspections_company_id ON public.property_inspections USING btree (company_id);

--
-- Name: idx_property_inspections_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_inspections_location_id ON public.property_inspections USING btree (location_id);

--
-- Name: idx_property_inspections_valid_until; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_inspections_valid_until ON public.property_inspections USING btree (valid_until);

--
-- Name: idx_property_issues_assigned_staff_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_issues_assigned_staff_vps ON public.property_issues USING btree (assigned_staff_id);

--
-- Name: idx_property_issues_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_issues_location_id ON public.property_issues USING btree (location_id);

--
-- Name: idx_property_issues_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_issues_org_id ON public.property_issues USING btree (org_id);

--
-- Name: idx_property_issues_org_status_created_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_issues_org_status_created_vps ON public.property_issues USING btree (org_id, status, created_at DESC);

--
-- Name: idx_property_issues_reporter_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_issues_reporter_id ON public.property_issues USING btree (reporter_id);

--
-- Name: idx_property_policies_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_policies_company_id ON public.property_policies USING btree (company_id);

--
-- Name: idx_property_policies_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_policies_location_id ON public.property_policies USING btree (location_id);

--
-- Name: idx_property_sections_assigned_staff_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_sections_assigned_staff_location ON public.property_sections USING btree (assigned_staff_id, location_id) WHERE ((assigned_staff_id IS NOT NULL) AND (location_id IS NOT NULL));

--
-- Name: idx_property_sections_location_assigned_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_sections_location_assigned_vps ON public.property_sections USING btree (location_id, assigned_staff_id);

--
-- Name: idx_property_sections_sort_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_sections_sort_order ON public.property_sections USING btree (location_id, sort_order);

--
-- Name: idx_property_tasks_community; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_tasks_community ON public.property_tasks USING btree (community_id);

--
-- Name: idx_property_tasks_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_tasks_location_id ON public.property_tasks USING btree (location_id);

--
-- Name: idx_property_tasks_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_property_tasks_status ON public.property_tasks USING btree (status);

--
-- Name: idx_repair_logs_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_repair_logs_org_id ON public.repair_logs USING btree (org_id);

--
-- Name: idx_resident_configs_org; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resident_configs_org ON public.resident_configs USING btree (org_id);

--
-- Name: idx_routing_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_routing_location ON public.location_vendor_routing USING btree (location_id);

--
-- Name: idx_routing_org; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_routing_org ON public.location_vendor_routing USING btree (org_id);

--
-- Name: idx_staff_equipment_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_equipment_org_id ON public.staff_equipment USING btree (org_id);

--
-- Name: idx_staff_equipment_staff_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_equipment_staff_id ON public.staff_equipment USING btree (staff_id);

--
-- Name: idx_staff_internal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_internal_id ON public.cleaning_staff USING btree (internal_id);

--
-- Name: idx_staff_payouts_month_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_payouts_month_year ON public.staff_payouts USING btree (year, month);

--
-- Name: idx_staff_payouts_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_payouts_org_id ON public.staff_payouts USING btree (org_id);

--
-- Name: idx_staff_payouts_paid_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_payouts_paid_by ON public.staff_payouts USING btree (paid_by);

--
-- Name: idx_staff_payouts_staff_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_payouts_staff_id ON public.staff_payouts USING btree (staff_id);

--
-- Name: idx_task_comments_task_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_comments_task_id ON public.task_comments USING btree (task_id);

--
-- Name: idx_task_execution_logs_task_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_execution_logs_task_id ON public.task_execution_logs USING btree (task_id);

--
-- Name: idx_task_execution_logs_user_created_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_execution_logs_user_created_vps ON public.task_execution_logs USING btree (user_id, created_at DESC);

--
-- Name: idx_task_execution_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_execution_logs_user_id ON public.task_execution_logs USING btree (user_id);

--
-- Name: idx_task_step_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_step_logs_created_at ON public.task_step_logs USING btree (created_at DESC);

--
-- Name: idx_task_step_logs_task_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_step_logs_task_id ON public.task_step_logs USING btree (task_id);

--
-- Name: idx_task_step_logs_user_created_vps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_step_logs_user_created_vps ON public.task_step_logs USING btree (user_id, created_at DESC);

--
-- Name: idx_task_step_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_step_logs_user_id ON public.task_step_logs USING btree (user_id);

--
-- Name: idx_tasks_assigned_to; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tasks_assigned_to ON public.internal_tasks USING btree (assigned_to);

--
-- Name: idx_tasks_duplicate_check; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tasks_duplicate_check ON public.cleaning_tasks USING btree (location_id, section_id, id, scheduled_at);

--
-- Name: idx_tasks_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tasks_lookup ON public.cleaning_tasks USING btree (assigned_staff_id, org_id);

--
-- Name: idx_tasks_template_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tasks_template_date ON public.cleaning_tasks USING btree (id, scheduled_at, location_id);

--
-- Name: idx_unit_records_campaign; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_unit_records_campaign ON public.unit_inspection_records USING btree (campaign_id);

--
-- Name: idx_vehicles_assigned_driver_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_assigned_driver_id ON public.vehicles USING btree (assigned_driver_id);

--
-- Name: idx_vehicles_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_org_id ON public.vehicles USING btree (org_id);

--
-- Name: unique_checklist_json_task_per_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_checklist_json_task_per_day ON public.cleaning_tasks USING btree (((checklist ->> 'id'::text)), (((scheduled_at AT TIME ZONE 'UTC'::text))::date)) WHERE (checklist IS NOT NULL);

--
-- Name: admin_contracts admin_contracts_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_contracts
    ADD CONSTRAINT admin_contracts_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: admin_contracts admin_contracts_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_contracts
    ADD CONSTRAINT admin_contracts_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor_partners(id);

--
-- Name: cleaning_inventory cleaning_inventory_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_inventory
    ADD CONSTRAINT cleaning_inventory_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.cleaning_catalog(id);

--
-- Name: cleaning_inventory cleaning_inventory_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_inventory
    ADD CONSTRAINT cleaning_inventory_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: cleaning_locations cleaning_locations_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_locations
    ADD CONSTRAINT cleaning_locations_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.cleaning_clients(id) ON DELETE CASCADE;

--
-- Name: cleaning_locations cleaning_locations_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_locations
    ADD CONSTRAINT cleaning_locations_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id) ON DELETE SET NULL;

--
-- Name: cleaning_locations cleaning_locations_location_master_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_locations
    ADD CONSTRAINT cleaning_locations_location_master_id_fkey FOREIGN KEY (location_master_id) REFERENCES public.locations(id);

--
-- Name: cleaning_staff cleaning_staff_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_staff
    ADD CONSTRAINT cleaning_staff_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: cleaning_tasks cleaning_tasks_actual_performer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_tasks
    ADD CONSTRAINT cleaning_tasks_actual_performer_id_fkey FOREIGN KEY (actual_performer_id) REFERENCES auth.users(id);

--
-- Name: cleaning_tasks cleaning_tasks_assigned_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_tasks
    ADD CONSTRAINT cleaning_tasks_assigned_staff_id_fkey FOREIGN KEY (assigned_staff_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

--
-- Name: cleaning_tasks cleaning_tasks_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_tasks
    ADD CONSTRAINT cleaning_tasks_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: cleaning_tasks cleaning_tasks_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleaning_tasks
    ADD CONSTRAINT cleaning_tasks_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.property_sections(id);

--
-- Name: communities communities_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.communities
    ADD CONSTRAINT communities_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: community_board community_board_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_board
    ADD CONSTRAINT community_board_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id);

--
-- Name: community_board community_board_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_board
    ADD CONSTRAINT community_board_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: community_board community_board_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_board
    ADD CONSTRAINT community_board_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: community_comments community_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_comments
    ADD CONSTRAINT community_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

--
-- Name: community_comments community_comments_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_comments
    ADD CONSTRAINT community_comments_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: community_comments community_comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_comments
    ADD CONSTRAINT community_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.community_board(id) ON DELETE CASCADE;

--
-- Name: companies companies_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: e_board_messages e_board_messages_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.e_board_messages
    ADD CONSTRAINT e_board_messages_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

--
-- Name: e_board_messages e_board_messages_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.e_board_messages
    ADD CONSTRAINT e_board_messages_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id) ON DELETE CASCADE;

--
-- Name: e_board_messages e_board_messages_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.e_board_messages
    ADD CONSTRAINT e_board_messages_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);

--
-- Name: e_board_messages e_board_messages_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.e_board_messages
    ADD CONSTRAINT e_board_messages_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: fuel_logs fuel_logs_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fuel_logs
    ADD CONSTRAINT fuel_logs_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.profiles(id);

--
-- Name: fuel_logs fuel_logs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fuel_logs
    ADD CONSTRAINT fuel_logs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: fuel_logs fuel_logs_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fuel_logs
    ADD CONSTRAINT fuel_logs_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;

--
-- Name: inspection_campaigns inspection_campaigns_e_board_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspection_campaigns
    ADD CONSTRAINT inspection_campaigns_e_board_message_id_fkey FOREIGN KEY (e_board_message_id) REFERENCES public.e_board_messages(id) ON DELETE SET NULL;

--
-- Name: inspection_campaigns inspection_campaigns_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspection_campaigns
    ADD CONSTRAINT inspection_campaigns_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: inspection_campaigns inspection_campaigns_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspection_campaigns
    ADD CONSTRAINT inspection_campaigns_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: inspection_campaigns inspection_campaigns_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspection_campaigns
    ADD CONSTRAINT inspection_campaigns_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor_partners(id) ON DELETE SET NULL;

--
-- Name: inspections_hybrid inspections_hybrid_assigned_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspections_hybrid
    ADD CONSTRAINT inspections_hybrid_assigned_vendor_id_fkey FOREIGN KEY (assigned_vendor_id) REFERENCES public.vendor_partners(id);

--
-- Name: inspections_hybrid inspections_hybrid_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspections_hybrid
    ADD CONSTRAINT inspections_hybrid_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: inspections inspections_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inspections
    ADD CONSTRAINT inspections_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: internal_tasks internal_tasks_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.internal_tasks
    ADD CONSTRAINT internal_tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id);

--
-- Name: internal_tasks internal_tasks_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.internal_tasks
    ADD CONSTRAINT internal_tasks_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id) ON DELETE CASCADE;

--
-- Name: internal_tasks internal_tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.internal_tasks
    ADD CONSTRAINT internal_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);

--
-- Name: internal_tasks internal_tasks_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.internal_tasks
    ADD CONSTRAINT internal_tasks_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE SET NULL;

--
-- Name: legal_documents legal_documents_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.legal_documents
    ADD CONSTRAINT legal_documents_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

--
-- Name: location_access location_access_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_access
    ADD CONSTRAINT location_access_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id);

--
-- Name: location_access location_access_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_access
    ADD CONSTRAINT location_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

--
-- Name: location_holidays location_holidays_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_holidays
    ADD CONSTRAINT location_holidays_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);

--
-- Name: location_holidays location_holidays_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_holidays
    ADD CONSTRAINT location_holidays_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: location_holidays location_holidays_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_holidays
    ADD CONSTRAINT location_holidays_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: location_vendor_routing location_vendor_routing_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_vendor_routing
    ADD CONSTRAINT location_vendor_routing_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: location_vendor_routing location_vendor_routing_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_vendor_routing
    ADD CONSTRAINT location_vendor_routing_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: location_vendor_routing location_vendor_routing_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_vendor_routing
    ADD CONSTRAINT location_vendor_routing_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor_partners(id) ON DELETE CASCADE;

--
-- Name: locations locations_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: material_requests material_requests_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_requests
    ADD CONSTRAINT material_requests_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id);

--
-- Name: material_requests material_requests_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_requests
    ADD CONSTRAINT material_requests_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id);

--
-- Name: material_requests material_requests_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_requests
    ADD CONSTRAINT material_requests_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.profiles(id);

--
-- Name: memberships memberships_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: memberships memberships_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

--
-- Name: offer_interactions offer_interactions_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offer_interactions
    ADD CONSTRAINT offer_interactions_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id);

--
-- Name: offer_interactions offer_interactions_offer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offer_interactions
    ADD CONSTRAINT offer_interactions_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.partner_offers(id);

--
-- Name: offer_interactions offer_interactions_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offer_interactions
    ADD CONSTRAINT offer_interactions_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id);

--
-- Name: offer_interactions offer_interactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offer_interactions
    ADD CONSTRAINT offer_interactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);

--
-- Name: org_subscriptions org_subscriptions_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_subscriptions
    ADD CONSTRAINT org_subscriptions_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.applications(id) ON DELETE CASCADE;

--
-- Name: org_subscriptions org_subscriptions_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_subscriptions
    ADD CONSTRAINT org_subscriptions_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: organizations organizations_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES auth.users(id);

--
-- Name: partner_offers partner_offers_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_offers
    ADD CONSTRAINT partner_offers_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: partner_offers partner_offers_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_offers
    ADD CONSTRAINT partner_offers_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: partner_offers partner_offers_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_offers
    ADD CONSTRAINT partner_offers_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor_partners(id) ON DELETE CASCADE;

--
-- Name: pricing_plans pricing_plans_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pricing_plans
    ADD CONSTRAINT pricing_plans_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.applications(id) ON DELETE CASCADE;

--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

--
-- Name: profiles profiles_last_active_location_access_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_last_active_location_access_id_fkey FOREIGN KEY (last_active_location_access_id) REFERENCES public.location_access(id) ON DELETE SET NULL;

--
-- Name: property_checklists property_checklists_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_checklists
    ADD CONSTRAINT property_checklists_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id);

--
-- Name: property_checklists property_checklists_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_checklists
    ADD CONSTRAINT property_checklists_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id);

--
-- Name: property_checklists property_checklists_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_checklists
    ADD CONSTRAINT property_checklists_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.property_sections(id);

--
-- Name: property_contracts property_contracts_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_contracts
    ADD CONSTRAINT property_contracts_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id) ON DELETE CASCADE;

--
-- Name: property_contracts property_contracts_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_contracts
    ADD CONSTRAINT property_contracts_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE RESTRICT;

--
-- Name: property_contracts property_contracts_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_contracts
    ADD CONSTRAINT property_contracts_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: property_inspections property_inspections_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_inspections
    ADD CONSTRAINT property_inspections_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE RESTRICT;

--
-- Name: property_inspections property_inspections_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_inspections
    ADD CONSTRAINT property_inspections_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: property_issues property_issues_assigned_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_issues
    ADD CONSTRAINT property_issues_assigned_staff_id_fkey FOREIGN KEY (assigned_staff_id) REFERENCES public.profiles(id);

--
-- Name: property_issues property_issues_claimed_by_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_issues
    ADD CONSTRAINT property_issues_claimed_by_org_id_fkey FOREIGN KEY (claimed_by_org_id) REFERENCES public.organizations(id);

--
-- Name: property_issues property_issues_delegated_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_issues
    ADD CONSTRAINT property_issues_delegated_vendor_id_fkey FOREIGN KEY (delegated_vendor_id) REFERENCES public.vendor_partners(id);

--
-- Name: property_issues property_issues_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_issues
    ADD CONSTRAINT property_issues_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id);

--
-- Name: property_issues property_issues_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_issues
    ADD CONSTRAINT property_issues_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id);

--
-- Name: property_issues property_issues_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_issues
    ADD CONSTRAINT property_issues_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id);

--
-- Name: property_policies property_policies_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_policies
    ADD CONSTRAINT property_policies_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id) ON DELETE CASCADE;

--
-- Name: property_policies property_policies_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_policies
    ADD CONSTRAINT property_policies_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE RESTRICT;

--
-- Name: property_policies property_policies_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_policies
    ADD CONSTRAINT property_policies_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: property_sections property_sections_assigned_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_sections
    ADD CONSTRAINT property_sections_assigned_staff_id_fkey FOREIGN KEY (assigned_staff_id) REFERENCES auth.users(id) ON DELETE SET NULL;

--
-- Name: property_sections property_sections_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_sections
    ADD CONSTRAINT property_sections_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: property_tasks property_tasks_assignee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_tasks
    ADD CONSTRAINT property_tasks_assignee_id_fkey FOREIGN KEY (assignee_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

--
-- Name: property_tasks property_tasks_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_tasks
    ADD CONSTRAINT property_tasks_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id) ON DELETE CASCADE;

--
-- Name: property_tasks property_tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_tasks
    ADD CONSTRAINT property_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);

--
-- Name: property_tasks property_tasks_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_tasks
    ADD CONSTRAINT property_tasks_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: repair_logs repair_logs_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repair_logs
    ADD CONSTRAINT repair_logs_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;

--
-- Name: resident_configs resident_configs_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resident_configs
    ADD CONSTRAINT resident_configs_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.cleaning_locations(id) ON DELETE CASCADE;

--
-- Name: resident_configs resident_configs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resident_configs
    ADD CONSTRAINT resident_configs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: staff_equipment staff_equipment_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_equipment
    ADD CONSTRAINT staff_equipment_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: staff_equipment staff_equipment_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_equipment
    ADD CONSTRAINT staff_equipment_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

--
-- Name: staff_financial_adjustments staff_financial_adjustments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_financial_adjustments
    ADD CONSTRAINT staff_financial_adjustments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

--
-- Name: staff_payouts staff_payouts_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payouts
    ADD CONSTRAINT staff_payouts_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: staff_payouts staff_payouts_paid_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payouts
    ADD CONSTRAINT staff_payouts_paid_by_fkey FOREIGN KEY (paid_by) REFERENCES public.profiles(id);

--
-- Name: staff_payouts staff_payouts_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payouts
    ADD CONSTRAINT staff_payouts_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

--
-- Name: staff_rate_history staff_rate_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_rate_history
    ADD CONSTRAINT staff_rate_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES auth.users(id);

--
-- Name: staff_rate_history staff_rate_history_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_rate_history
    ADD CONSTRAINT staff_rate_history_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

--
-- Name: task_comments task_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id);

--
-- Name: task_comments task_comments_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.property_tasks(id) ON DELETE CASCADE;

--
-- Name: task_execution_logs task_execution_logs_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_execution_logs
    ADD CONSTRAINT task_execution_logs_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.cleaning_tasks(id);

--
-- Name: task_execution_logs task_execution_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_execution_logs
    ADD CONSTRAINT task_execution_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

--
-- Name: task_step_logs task_step_logs_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_step_logs
    ADD CONSTRAINT task_step_logs_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.cleaning_tasks(id);

--
-- Name: task_step_logs task_step_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_step_logs
    ADD CONSTRAINT task_step_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);

--
-- Name: unit_inspection_records unit_inspection_records_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unit_inspection_records
    ADD CONSTRAINT unit_inspection_records_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.inspection_campaigns(id) ON DELETE CASCADE;

--
-- Name: vehicles vehicles_assigned_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_assigned_driver_id_fkey FOREIGN KEY (assigned_driver_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

--
-- Name: vehicles vehicles_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

--
-- Name: supabase_realtime property_issues; Type: PUBLICATION TABLE; Schema: public; Owner: postgres
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.property_issues;

--
-- Name: can_manage_location(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.can_manage_location(target_location_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_org_id uuid;
BEGIN
  -- Pobieramy organizację budynku
  SELECT org_id INTO v_org_id FROM cleaning_locations WHERE id = target_location_id;
  
  -- Jeśli brak budynku, dostęp zabroniony
  IF v_org_id IS NULL THEN RETURN false; END IF;
  
  -- Sprawdzamy uprawnienia (Owner, Manager, Admin, COORDINATOR)
  RETURN EXISTS (
    SELECT 1 FROM memberships
    WHERE org_id = v_org_id
    AND user_id = auth.uid()
    AND role ILIKE ANY (ARRAY['owner', 'manager', 'admin', 'coordinator'])
  );
END;
$$;


ALTER FUNCTION public.can_manage_location(target_location_id uuid) OWNER TO postgres;

--
-- Name: check_is_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_is_admin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = auth.uid() AND role IN ('owner', 'coordinator')
  );
$$;


ALTER FUNCTION public.check_is_admin() OWNER TO postgres;

--
-- Name: check_location_manager(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_location_manager(target_location_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_org_id uuid;
BEGIN
  SELECT org_id INTO v_org_id FROM cleaning_locations WHERE id = target_location_id;
  IF v_org_id IS NULL THEN RETURN false; END IF;
  
  -- Sprawdź czy user jest szefem/managerem w tej organizacji
  RETURN EXISTS (
    SELECT 1 FROM memberships
    WHERE org_id = v_org_id
    AND user_id = auth.uid()
    AND role ILIKE ANY (ARRAY['owner', 'manager', 'admin', 'coordinator'])
  );
END;
$$;


ALTER FUNCTION public.check_location_manager(target_location_id uuid) OWNER TO postgres;

--
-- Name: check_location_proximity(uuid, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_location_proximity(p_location_id uuid, p_user_latitude double precision, p_user_longitude double precision) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_lat DOUBLE PRECISION;
  v_lng DOUBLE PRECISION;
  v_geofence_radius_meters DOUBLE PRECISION;
  v_location_geo GEOGRAPHY;
  v_user_geo GEOGRAPHY;
  v_distance_meters DOUBLE PRECISION;
  v_is_within_range BOOLEAN;
BEGIN
  -- Pobieramy tylko nowe współrzędne i promień (domyślnie 100m)
  SELECT 
    latitude,
    longitude,
    COALESCE(geofence_radius_meters, 100.0)
  INTO 
    v_lat,
    v_lng,
    v_geofence_radius_meters
  FROM public.cleaning_locations
  WHERE id = p_location_id;

  -- Jeśli budynek nie ma wpisanych współrzędnych, przerywamy
  IF v_lat IS NULL OR v_lng IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Obiekt nie posiada skonfigurowanych współrzędnych GPS (latitude/longitude)'
    );
  END IF;

  -- Budowanie punktów geograficznych (WGS84)
  v_location_geo := ST_SetSRID(ST_MakePoint(v_lng, v_lat), 4326)::GEOGRAPHY;
  v_user_geo := ST_SetSRID(ST_MakePoint(p_user_longitude, p_user_latitude), 4326)::GEOGRAPHY;

  -- Obliczenia precyzyjne za pomocą PostGIS
  v_distance_meters := ST_Distance(v_location_geo, v_user_geo, true);
  v_is_within_range := ST_DWithin(v_location_geo, v_user_geo, v_geofence_radius_meters, true);

  RETURN json_build_object(
    'success', true,
    'is_within_range', v_is_within_range,
    'distance_meters', ROUND(v_distance_meters::numeric, 2),
    'geofence_radius_meters', v_geofence_radius_meters,
    'user_coordinates', json_build_object('lat', p_user_latitude, 'lng', p_user_longitude),
    'location_coordinates', json_build_object('lat', v_lat, 'lng', v_lng)
  );
END;
$$;


ALTER FUNCTION public.check_location_proximity(p_location_id uuid, p_user_latitude double precision, p_user_longitude double precision) OWNER TO postgres;

--
-- Name: check_manager_access(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_manager_access(target_org_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM memberships
    WHERE org_id = target_org_id
    AND user_id = auth.uid()
    AND role ILIKE ANY (ARRAY['owner', 'manager', 'admin', 'coordinator'])
  );
$$;


ALTER FUNCTION public.check_manager_access(target_org_id uuid) OWNER TO postgres;

--
-- Name: check_org_access(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_org_access(target_org_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
SELECT EXISTS (
  SELECT 1 
  FROM public.memberships 
  WHERE org_id = target_org_id 
  AND user_id = auth.uid()
);
$$;


ALTER FUNCTION public.check_org_access(target_org_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION check_org_access(target_org_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.check_org_access(target_org_id uuid) IS 'Sprawdza czy zalogowany użytkownik ma dostęp do organizacji o podanym org_id. Używana w politykach RLS.';

--
-- Name: check_slug_available(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_slug_available(p_slug text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF p_slug IS NULL OR trim(p_slug) = '' THEN
    RETURN false;
  END IF;

  -- Taken if exists in profiles (technical staff email) or cleaning_staff (internal_id)
  IF EXISTS (
    SELECT 1 FROM public.profiles
    WHERE email IS NOT NULL AND email = trim(p_slug) || '@staff.domio.com.pl'
  ) THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.cleaning_staff
    WHERE internal_id IS NOT NULL AND internal_id = trim(p_slug)
  ) THEN
    RETURN false;
  END IF;

  RETURN true;
END;
$$;


ALTER FUNCTION public.check_slug_available(p_slug text) OWNER TO postgres;

--
-- Name: FUNCTION check_slug_available(p_slug text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.check_slug_available(p_slug text) IS 'Returns true if slug is available for new worker login (checks profiles.email and cleaning_staff.internal_id).';

--
-- Name: check_user_belongs_to_org(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_user_belongs_to_org(p_org_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = auth.uid() AND org_id = p_org_id
  );
$$;


ALTER FUNCTION public.check_user_belongs_to_org(p_org_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION check_user_belongs_to_org(p_org_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.check_user_belongs_to_org(p_org_id uuid) IS 'Returns true if auth.uid() has a membership for the given org_id. Used by RLS for org-scoped SELECT.';

--
-- Name: complete_task(uuid, text[], text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.complete_task(p_task_id uuid, p_photo_urls text[], p_notes text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    UPDATE public.cleaning_tasks
    SET 
        status = 'done',
        completed_at = NOW(),
        check_out_metadata = jsonb_build_object(
            'photos', p_photo_urls,
            'staff_notes', p_notes
        )
    WHERE id = p_task_id AND assigned_staff_id = auth.uid();
END;
$$;


ALTER FUNCTION public.complete_task(p_task_id uuid, p_photo_urls text[], p_notes text) OWNER TO postgres;

--
-- Name: enforce_company_matches_location_org(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enforce_company_matches_location_org() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  loc_org uuid;
  comp_org uuid;
BEGIN
  SELECT cl.org_id INTO loc_org
  FROM public.cleaning_locations cl
  WHERE cl.id = NEW.location_id;

  SELECT c.org_id INTO comp_org
  FROM public.companies c
  WHERE c.id = NEW.company_id;

  IF loc_org IS NULL THEN
    RAISE EXCEPTION 'location not found';
  END IF;

  IF comp_org IS NULL THEN
    RAISE EXCEPTION 'company not found';
  END IF;

  IF loc_org IS DISTINCT FROM comp_org THEN
    RAISE EXCEPTION 'company org_id must match cleaning_locations.org_id for this location';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.enforce_company_matches_location_org() OWNER TO postgres;

--
-- Name: get_auth_org_ids(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_auth_org_ids() RETURNS TABLE(o_id uuid)
    LANGUAGE sql SECURITY DEFINER
    AS $$
  SELECT org_id FROM memberships WHERE user_id = auth.uid();
$$;


ALTER FUNCTION public.get_auth_org_ids() OWNER TO postgres;

--
-- Name: get_fleet_analytics(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_fleet_analytics(p_org_id uuid) RETURNS TABLE(vehicle_id uuid, total_fuel_cost numeric, total_repair_cost numeric, avg_consumption numeric, last_mileage integer)
    LANGUAGE plpgsql
    AS $$BEGIN
    RETURN QUERY
    SELECT 
        v.id as vehicle_id,
        COALESCE(SUM(fl.cost), 0) as total_fuel_cost,
        COALESCE(SUM(rl.cost), 0) as total_repair_cost,
        COALESCE(AVG(fl.liters / NULLIF(fl.current_mileage, 0)) * 100, 0) as avg_consumption,
        MAX(fl.current_mileage) as last_mileage
    FROM public.vehicles v
    LEFT JOIN public.fuel_logs fl ON fl.vehicle_id = v.id
    LEFT JOIN public.repair_logs rl ON rl.vehicle_id = v.id
    WHERE v.org_id = p_org_id
    GROUP BY v.id;
END;$$;


ALTER FUNCTION public.get_fleet_analytics(p_org_id uuid) OWNER TO postgres;

--
-- Name: get_location_org_id_safe(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_location_org_id_safe(target_location_id uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT org_id FROM public.cleaning_locations WHERE id = target_location_id;
$$;


ALTER FUNCTION public.get_location_org_id_safe(target_location_id uuid) OWNER TO postgres;

--
-- Name: get_my_claims(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_claims() RETURNS TABLE(org_id uuid, role text)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT org_id, role 
  FROM public.memberships 
  WHERE user_id = auth.uid();
$$;


ALTER FUNCTION public.get_my_claims() OWNER TO postgres;

--
-- Name: get_my_org_and_role(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_org_and_role() RETURNS TABLE(org_id uuid, role text)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT org_id, role FROM public.memberships WHERE user_id = auth.uid();
$$;


ALTER FUNCTION public.get_my_org_and_role() OWNER TO postgres;

--
-- Name: get_my_org_id_safe(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_org_id_safe() RETURNS uuid
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT org_id FROM memberships WHERE user_id = auth.uid() LIMIT 1;
$$;


ALTER FUNCTION public.get_my_org_id_safe() OWNER TO postgres;

--
-- Name: get_my_org_ids(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_org_ids() RETURNS TABLE(org_id uuid)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT org_id FROM public.memberships WHERE user_id = auth.uid();
$$;


ALTER FUNCTION public.get_my_org_ids() OWNER TO postgres;

--
-- Name: get_my_org_ids_safe(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_org_ids_safe() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT org_id FROM public.memberships WHERE user_id = auth.uid();
$$;


ALTER FUNCTION public.get_my_org_ids_safe() OWNER TO postgres;

--
-- Name: get_my_orgs(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_orgs() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT org_id FROM memberships WHERE user_id = auth.uid();
$$;


ALTER FUNCTION public.get_my_orgs() OWNER TO postgres;

--
-- Name: get_my_orgs_safe(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_orgs_safe() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT org_id FROM public.memberships WHERE user_id = auth.uid();
$$;


ALTER FUNCTION public.get_my_orgs_safe() OWNER TO postgres;

--
-- Name: get_profile_by_email(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_profile_by_email(target_email text) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
DECLARE
  result json;
BEGIN
  -- 1. Próba znalezienia w PROFILES (tam są imiona i nazwiska)
  SELECT json_build_object(
    'id', p.id,
    'full_name', p.full_name,
    'email', p.email,
    'source', 'profile'
  ) INTO result
  FROM public.profiles p
  WHERE LOWER(TRIM(p.email)) = LOWER(TRIM(target_email))
  LIMIT 1;

  -- 2. Jeśli brak w profilach, szukamy w AUTH.USERS (tam są loginy)
  IF result IS NULL THEN
    SELECT json_build_object(
      'id', u.id,
      'full_name', '', -- Auth nie przechowuje imion, zwracamy puste
      'email', u.email,
      'source', 'auth'
    ) INTO result
    FROM auth.users u
    WHERE LOWER(TRIM(u.email)) = LOWER(TRIM(target_email))
    LIMIT 1;
  END IF;

  RETURN result;
END;
$$;


ALTER FUNCTION public.get_profile_by_email(target_email text) OWNER TO postgres;

--
-- Name: get_property_tasks_with_comment_counts(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_property_tasks_with_comment_counts(p_location_id uuid) RETURNS TABLE(id uuid, location_id uuid, title text, status public.property_task_status, priority public.property_task_priority, visibility public.property_task_visibility, assignee_id uuid, created_by uuid, created_at timestamp with time zone, comments_count bigint)
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  SELECT
    pt.id,
    pt.location_id,
    pt.title,
    pt.status,
    pt.priority,
    pt.visibility,
    pt.assignee_id,
    pt.created_by,
    pt.created_at,
    (
      SELECT count(*)::bigint
      FROM public.task_comments tc
      WHERE tc.task_id = pt.id
    ) AS comments_count
  FROM public.property_tasks pt
  WHERE pt.location_id = p_location_id
  ORDER BY pt.created_at DESC;
$$;


ALTER FUNCTION public.get_property_tasks_with_comment_counts(p_location_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION get_property_tasks_with_comment_counts(p_location_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_property_tasks_with_comment_counts(p_location_id uuid) IS 'Lists property_tasks for a location with aggregated comment counts; RLS applies per row.';

--
-- Name: get_user_highest_role(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_highest_role(p_org_id uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  SELECT role FROM public.memberships 
  WHERE user_id = auth.uid() AND org_id = p_org_id
  ORDER BY 
    CASE role 
      WHEN 'owner' THEN 1 
      WHEN 'coordinator' THEN 2 
      WHEN 'cleaner' THEN 3 
      ELSE 4 
    END
  LIMIT 1;
$$;


ALTER FUNCTION public.get_user_highest_role(p_org_id uuid) OWNER TO postgres;

--
-- Name: handle_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.handle_updated_at() OWNER TO postgres;

--
-- Name: has_location_access(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_location_access(target_location_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    -- 1. Stały dostęp (klucze)
    SELECT 1 FROM public.location_access
    WHERE user_id = auth.uid() AND location_id = target_location_id
    UNION ALL
    -- 2. Zadania (na dziś lub ogólnie)
    SELECT 1 FROM public.cleaning_tasks
    WHERE assigned_staff_id = auth.uid() AND location_id = target_location_id
    UNION ALL
    -- 3. Sekcje (przypisanie do strefy)
    SELECT 1 FROM public.property_sections
    WHERE assigned_staff_id = auth.uid() AND location_id = target_location_id
  );
$$;


ALTER FUNCTION public.has_location_access(target_location_id uuid) OWNER TO postgres;

--
-- Name: has_staff_access_safe(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.has_staff_access_safe(target_location_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.location_access WHERE user_id = auth.uid() AND location_id = target_location_id
    UNION ALL
    SELECT 1 FROM public.cleaning_tasks WHERE assigned_staff_id = auth.uid() AND location_id = target_location_id
    UNION ALL
    SELECT 1 FROM public.property_sections WHERE assigned_staff_id = auth.uid() AND location_id = target_location_id
  );
$$;


ALTER FUNCTION public.has_staff_access_safe(target_location_id uuid) OWNER TO postgres;

--
-- Name: is_admin_safe(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_admin_safe(target_org_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE org_id = target_org_id
    AND user_id = auth.uid()
    AND role ILIKE ANY (ARRAY['owner', 'admin', 'manager', 'coordinator']) -- ILIKE = ignoruj wielkość liter
  );
$$;


ALTER FUNCTION public.is_admin_safe(target_org_id uuid) OWNER TO postgres;

--
-- Name: is_management_role(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_management_role(target_org_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
SELECT EXISTS (
  SELECT 1 
  FROM public.memberships 
  WHERE org_id = target_org_id 
  AND user_id = auth.uid()
  AND role IN ('owner', 'admin', 'coordinator')
);
$$;


ALTER FUNCTION public.is_management_role(target_org_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION is_management_role(target_org_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.is_management_role(target_org_id uuid) IS 'Sprawdza czy zalogowany użytkownik ma rolę zarządzającą (owner/admin/coordinator) w organizacji. Używana w politykach RLS.';

--
-- Name: is_manager(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_manager() RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM memberships 
    WHERE user_id = auth.uid() 
    AND role IN ('owner', 'admin', 'coordinator')
  );
$$;


ALTER FUNCTION public.is_manager() OWNER TO postgres;

--
-- Name: is_manager_safe(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_manager_safe() RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM memberships 
    WHERE user_id = auth.uid() 
    AND role IN ('owner', 'admin', 'coordinator')
  );
$$;


ALTER FUNCTION public.is_manager_safe() OWNER TO postgres;

--
-- Name: is_org_manager(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_org_manager(target_org_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = auth.uid()
    AND org_id = target_org_id
    AND role IN ('owner', 'manager', 'admin', 'coordinator')
  );
$$;


ALTER FUNCTION public.is_org_manager(target_org_id uuid) OWNER TO postgres;

--
-- Name: is_org_manager_safe(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_org_manager_safe(target_org_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = auth.uid()
    AND org_id = target_org_id
    -- Używamy ILIKE ANY dla ignorowania wielkości liter
    AND role ILIKE ANY (ARRAY['owner', 'manager', 'admin', 'coordinator'])
  );
$$;


ALTER FUNCTION public.is_org_manager_safe(target_org_id uuid) OWNER TO postgres;

--
-- Name: is_org_member(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_org_member(target_org_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.memberships 
        WHERE user_id = auth.uid() AND org_id = target_org_id
    );
END;
$$;


ALTER FUNCTION public.is_org_member(target_org_id uuid) OWNER TO postgres;

--
-- Name: is_platform_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_platform_admin() RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND platform_role = 'admin'
  );
$$;


ALTER FUNCTION public.is_platform_admin() OWNER TO postgres;

--
-- Name: link_user_to_org(uuid, uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.link_user_to_org(target_user_id uuid, target_org_id uuid, target_role text, target_full_name text, target_email text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- 1. Obsługa tabeli PROFILES
  -- ZMIANA: Dodajemy account_type = 'hub'
  INSERT INTO public.profiles (id, full_name, email, updated_at, accepted_terms_at, account_type)
  VALUES (target_user_id, target_full_name, target_email, now(), now(), 'hub')
  ON CONFLICT (id) DO UPDATE 
  SET email = EXCLUDED.email,
      full_name = COALESCE(NULLIF(public.profiles.full_name, ''), EXCLUDED.full_name),
      account_type = 'hub'; -- Jeśli profil był uproszczony, zmieniamy go na HUB

  -- 2. Obsługa tabeli MEMBERSHIPS
  IF NOT EXISTS (
    SELECT 1 FROM memberships 
    WHERE user_id = target_user_id AND org_id = target_org_id
  ) THEN
    INSERT INTO memberships (user_id, org_id, role)
    VALUES (target_user_id, target_org_id, target_role);
  END IF;

  -- 3. Obsługa tabeli CLEANING_STAFF
  INSERT INTO cleaning_staff (id, org_id, full_name, contact_email, status, employment_type)
  VALUES (target_user_id, target_org_id, target_full_name, target_email, 'active', 'b2b')
  ON CONFLICT (id) DO UPDATE 
  SET org_id = EXCLUDED.org_id,
      contact_email = EXCLUDED.contact_email,
      full_name = EXCLUDED.full_name;
END;
$$;


ALTER FUNCTION public.link_user_to_org(target_user_id uuid, target_org_id uuid, target_role text, target_full_name text, target_email text) OWNER TO postgres;

--
-- Name: log_rate_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_rate_changes() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    IF (OLD.base_hourly_rate IS DISTINCT FROM NEW.base_hourly_rate) OR
       (OLD.snow_hourly_rate IS DISTINCT FROM NEW.snow_hourly_rate) OR
       (OLD.fixed_salary IS DISTINCT FROM NEW.fixed_salary) THEN
       
        INSERT INTO staff_rate_history (
            staff_id, 
            base_hourly_rate, 
            snow_hourly_rate, 
            fixed_salary, 
            changed_by
        )
        VALUES (
            NEW.id,
            NEW.base_hourly_rate,
            NEW.snow_hourly_rate,
            NEW.fixed_salary,
            auth.uid()
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_rate_changes() OWNER TO postgres;

--
-- Name: property_task_location_id(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.property_task_location_id(p_task_id uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT location_id FROM public.property_tasks WHERE id = p_task_id;
$$;


ALTER FUNCTION public.property_task_location_id(p_task_id uuid) OWNER TO postgres;

--
-- Name: property_task_user_has_access(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.property_task_user_has_access(p_location_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.cleaning_locations cl
      INNER JOIN public.memberships m
        ON m.org_id = cl.org_id
       AND m.user_id = auth.uid()
       AND m.is_active = true
       AND lower(trim(m.role)) = 'owner'
      WHERE cl.id = p_location_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.location_access la
      WHERE la.location_id = p_location_id
        AND la.user_id = auth.uid()
        AND la.access_type = 'administration'
        AND (la.expires_at IS NULL OR la.expires_at > now())
    );
$$;


ALTER FUNCTION public.property_task_user_has_access(p_location_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION property_task_user_has_access(p_location_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.property_task_user_has_access(p_location_id uuid) IS 'True if current user is org Owner for the location or has administration location_access.';

--
-- Name: start_task_with_validation(uuid, double precision, double precision, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.start_task_with_validation(p_task_id uuid, p_user_lat double precision, p_user_lon double precision, p_scanned_qr text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_task RECORD;
    v_distance FLOAT;
    v_user_geo geography; -- Usunięto prefiks extensions.
BEGIN
    -- 1. Pobierz dane zadania i powiązanej lokalizacji
    SELECT t.*, l.geo_location, l.geofence_radius_meters, l.qr_code_token, l.validation_config
    INTO v_task
    FROM public.cleaning_tasks t
    JOIN public.cleaning_locations l ON t.location_id = l.id
    WHERE t.id = p_task_id AND t.assigned_staff_id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Zadanie nie istnieje lub nie masz do niego uprawnień.';
    END IF;

    -- 2. Walidacja kodu QR (jeśli wymagana)
    IF (v_task.validation_config->>'qr_required')::BOOLEAN AND v_task.qr_code_token != p_scanned_qr THEN
        RAISE EXCEPTION 'Nieprawidłowy kod QR dla tej lokalizacji.';
    END IF;

    -- 3. Walidacja GPS (jeśli wymagana)
    IF (v_task.validation_config->>'gps_required')::BOOLEAN THEN
        -- Tworzymy punkt geograficzny z parametrów
        v_user_geo := ST_SetSRID(ST_MakePoint(p_user_lon, p_user_lat), 4326)::geography;
        
        -- Obliczamy dystans w metrach
        v_distance := ST_Distance(v_user_geo, v_task.geo_location);

        IF v_distance > v_task.geofence_radius_meters THEN
            RAISE EXCEPTION 'Jesteś poza wyznaczonym obszarem pracy (Odległość: %m).', ROUND(v_distance::numeric, 2);
        END IF;
    END IF;

    -- 4. Aktualizacja statusu zadania
    UPDATE public.cleaning_tasks
    SET 
        status = 'in_progress',
        started_at = NOW(),
        check_in_metadata = jsonb_build_object(
            'lat', p_user_lat,
            'lon', p_user_lon,
            'distance_m', v_distance,
            'qr_verified', true,
            'timestamp', NOW()
        )
    WHERE id = p_task_id;

    RETURN jsonb_build_object('status', 'success', 'started_at', NOW(), 'distance_m', v_distance);
END;
$$;


ALTER FUNCTION public.start_task_with_validation(p_task_id uuid, p_user_lat double precision, p_user_lon double precision, p_scanned_qr text) OWNER TO postgres;

--
-- Name: update_location_holidays_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_location_holidays_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_location_holidays_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: upsert_company_by_tax_id(uuid, text, text, public.company_category, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.upsert_company_by_tax_id(p_org_id uuid, p_name text, p_tax_id text, p_category public.company_category, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text) RETURNS public.companies
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_row public.companies;
BEGIN
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'p_org_id is required';
  END IF;

  -- Authenticated users: must be active member of the target org (n8n / service role without uid skips).
  IF auth.uid() IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1
      FROM public.memberships m
      WHERE m.org_id = p_org_id
        AND m.user_id = auth.uid()
        AND coalesce(m.is_active, true) = true
    ) THEN
      RAISE EXCEPTION 'forbidden: not a member of this organization'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  INSERT INTO public.companies (name, tax_id, category, email, phone, address, org_id)
  VALUES (
    trim(p_name),
    trim(p_tax_id),
    p_category,
    p_email,
    p_phone,
    p_address,
    p_org_id
  )
  ON CONFLICT ON CONSTRAINT companies_tax_id_org_id_key DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    email = COALESCE(EXCLUDED.email, companies.email),
    phone = COALESCE(EXCLUDED.phone, companies.phone),
    address = COALESCE(EXCLUDED.address, companies.address),
    updated_at = now()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;


ALTER FUNCTION public.upsert_company_by_tax_id(p_org_id uuid, p_name text, p_tax_id text, p_category public.company_category, p_email text, p_phone text, p_address text) OWNER TO postgres;

--
-- Name: FUNCTION upsert_company_by_tax_id(p_org_id uuid, p_name text, p_tax_id text, p_category public.company_category, p_email text, p_phone text, p_address text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.upsert_company_by_tax_id(p_org_id uuid, p_name text, p_tax_id text, p_category public.company_category, p_email text, p_phone text, p_address text) IS 'Insert or update company by (tax_id, org_id) within a tenant; SECURITY DEFINER with membership check.';

--
-- Name: user_has_location_access_docs(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_location_access_docs(p_location_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.location_access la
    WHERE la.location_id = p_location_id
      AND la.user_id = auth.uid()
      AND (la.expires_at IS NULL OR la.expires_at > now())
  );
$$;


ALTER FUNCTION public.user_has_location_access_docs(p_location_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION user_has_location_access_docs(p_location_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.user_has_location_access_docs(p_location_id uuid) IS 'True if current user has a non-expired location_access row for the building.';

--
-- Name: property_inspections handle_updated_at_property_inspections; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER handle_updated_at_property_inspections BEFORE UPDATE ON public.property_inspections FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

--
-- Name: location_holidays location_holidays_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER location_holidays_updated_at BEFORE UPDATE ON public.location_holidays FOR EACH ROW EXECUTE FUNCTION public.update_location_holidays_updated_at();

--
-- Name: profiles on_rate_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER on_rate_change AFTER UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.log_rate_changes();

--
-- Name: companies set_updated_at_companies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at_companies BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

--
-- Name: property_contracts set_updated_at_contracts; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at_contracts BEFORE UPDATE ON public.property_contracts FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

--
-- Name: property_policies set_updated_at_policies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at_policies BEFORE UPDATE ON public.property_policies FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

--
-- Name: community_board update_community_board_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_community_board_updated_at BEFORE UPDATE ON public.community_board FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

--
-- Name: community_comments update_community_comments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_community_comments_updated_at BEFORE UPDATE ON public.community_comments FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

--
-- Name: partner_offers update_partner_offers_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_partner_offers_updated_at BEFORE UPDATE ON public.partner_offers FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

--
-- Name: resident_configs update_resident_configs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_resident_configs_updated_at BEFORE UPDATE ON public.resident_configs FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

--
-- Name: applications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

--
-- Name: cleaning_catalog; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.cleaning_catalog ENABLE ROW LEVEL SECURITY;

--
-- Name: cleaning_clients; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.cleaning_clients ENABLE ROW LEVEL SECURITY;

--
-- Name: cleaning_inventory; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.cleaning_inventory ENABLE ROW LEVEL SECURITY;

--
-- Name: cleaning_locations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.cleaning_locations ENABLE ROW LEVEL SECURITY;

--
-- Name: cleaning_staff; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.cleaning_staff ENABLE ROW LEVEL SECURITY;

--
-- Name: cleaning_tasks; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.cleaning_tasks ENABLE ROW LEVEL SECURITY;

--
-- Name: communities; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

--
-- Name: community_board; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.community_board ENABLE ROW LEVEL SECURITY;

--
-- Name: community_comments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;

--
-- Name: companies; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

--
-- Name: e_board_messages; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.e_board_messages ENABLE ROW LEVEL SECURITY;

--
-- Name: fuel_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.fuel_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: inspection_campaigns; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.inspection_campaigns ENABLE ROW LEVEL SECURITY;

--
-- Name: inspections; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;

--
-- Name: inspections_hybrid; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.inspections_hybrid ENABLE ROW LEVEL SECURITY;

--
-- Name: internal_tasks; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.internal_tasks ENABLE ROW LEVEL SECURITY;

--
-- Name: legal_documents; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: location_access; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.location_access ENABLE ROW LEVEL SECURITY;

--
-- Name: location_holidays; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.location_holidays ENABLE ROW LEVEL SECURITY;

--
-- Name: location_vendor_routing; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.location_vendor_routing ENABLE ROW LEVEL SECURITY;

--
-- Name: locations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

--
-- Name: material_requests; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.material_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: memberships; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.memberships ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_templates; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;

--
-- Name: offer_interactions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.offer_interactions ENABLE ROW LEVEL SECURITY;

--
-- Name: org_subscriptions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.org_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: organizations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

--
-- Name: page_content; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.page_content ENABLE ROW LEVEL SECURITY;

--
-- Name: partner_offers; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.partner_offers ENABLE ROW LEVEL SECURITY;

--
-- Name: pricing_plans; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.pricing_plans ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: promo_codes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: property_checklists; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.property_checklists ENABLE ROW LEVEL SECURITY;

--
-- Name: property_contracts; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.property_contracts ENABLE ROW LEVEL SECURITY;

--
-- Name: property_inspections; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.property_inspections ENABLE ROW LEVEL SECURITY;

--
-- Name: property_issues; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.property_issues ENABLE ROW LEVEL SECURITY;

--
-- Name: property_policies; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.property_policies ENABLE ROW LEVEL SECURITY;

--
-- Name: property_sections; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.property_sections ENABLE ROW LEVEL SECURITY;

--
-- Name: property_tasks; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.property_tasks ENABLE ROW LEVEL SECURITY;

--
-- Name: repair_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.repair_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: resident_configs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.resident_configs ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_equipment; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.staff_equipment ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_financial_adjustments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.staff_financial_adjustments ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_payouts; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.staff_payouts ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_rate_history; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.staff_rate_history ENABLE ROW LEVEL SECURITY;

--
-- Name: task_comments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

--
-- Name: task_execution_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.task_execution_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: task_step_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.task_step_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: unit_inspection_records; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.unit_inspection_records ENABLE ROW LEVEL SECURITY;

--
-- Name: vehicles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

--
-- Name: vendor_partners; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.vendor_partners ENABLE ROW LEVEL SECURITY;

--
-- Name: legal_documents Admin_all_access_documents; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admin_all_access_documents" ON public.legal_documents USING (public.is_platform_admin());

--
-- Name: inspection_campaigns Admins can manage campaigns; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage campaigns" ON public.inspection_campaigns USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid()))));

--
-- Name: e_board_messages Admins can manage e-board; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage e-board" ON public.e_board_messages USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid()))));

--
-- Name: staff_payouts Admins can manage payouts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage payouts" ON public.staff_payouts USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE ((memberships.user_id = auth.uid()) AND (memberships.role = ANY (ARRAY['owner'::text, 'coordinator'::text]))))));

--
-- Name: repair_logs Admins can manage repairs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage repairs" ON public.repair_logs USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE ((memberships.user_id = auth.uid()) AND (memberships.role = ANY (ARRAY['owner'::text, 'coordinator'::text]))))));

--
-- Name: location_vendor_routing Admins can manage routing; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage routing" ON public.location_vendor_routing USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE ((memberships.user_id = auth.uid()) AND (memberships.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))));

--
-- Name: notification_templates Admins can manage templates; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage templates" ON public.notification_templates USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE ((memberships.user_id = auth.uid()) AND (memberships.role = ANY (ARRAY['owner'::text, 'coordinator'::text]))))));

--
-- Name: communities Admins can manage their communities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage their communities" ON public.communities USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid()))));

--
-- Name: unit_inspection_records Admins can manage unit records; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage unit records" ON public.unit_inspection_records USING ((campaign_id IN ( SELECT inspection_campaigns.id
   FROM public.inspection_campaigns
  WHERE (inspection_campaigns.org_id IN ( SELECT memberships.org_id
           FROM public.memberships
          WHERE (memberships.user_id = auth.uid()))))));

--
-- Name: staff_rate_history Admins can view rate history; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view rate history" ON public.staff_rate_history FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.fleet_role)::text = ANY (ARRAY['admin'::text, 'owner'::text, 'manager'::text]))))));

--
-- Name: community_comments Admins manage community_comments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins manage community_comments" ON public.community_comments USING (public.is_management_role(org_id));

--
-- Name: cleaning_clients CORE_Clients_Manage; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "CORE_Clients_Manage" ON public.cleaning_clients USING ((EXISTS ( SELECT 1
   FROM public.get_my_org_and_role() get_my_org_and_role(org_id, role)
  WHERE ((get_my_org_and_role.org_id = cleaning_clients.org_id) AND (get_my_org_and_role.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))));

--
-- Name: location_access CORE_LocationAccess_Manage; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "CORE_LocationAccess_Manage" ON public.location_access USING ((EXISTS ( SELECT 1
   FROM (public.cleaning_locations cl
     JOIN public.memberships m ON ((m.org_id = cl.org_id)))
  WHERE ((cl.id = location_access.location_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text]))))));

--
-- Name: location_access CORE_LocationAccess_ViewOwn; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "CORE_LocationAccess_ViewOwn" ON public.location_access FOR SELECT USING ((user_id = auth.uid()));

--
-- Name: organizations CORE_Orgs_Manage; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "CORE_Orgs_Manage" ON public.organizations USING ((EXISTS ( SELECT 1
   FROM public.get_my_org_and_role() get_my_org_and_role(org_id, role)
  WHERE ((get_my_org_and_role.org_id = organizations.id) AND (get_my_org_and_role.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text]))))));

--
-- Name: cleaning_inventory Inventory_Manager_Access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Inventory_Manager_Access" ON public.cleaning_inventory USING (public.is_org_manager(org_id));

--
-- Name: cleaning_inventory Inventory_Staff_View; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Inventory_Staff_View" ON public.cleaning_inventory FOR SELECT USING (public.has_location_access(location_id));

--
-- Name: locations Locations_Master_Read_All; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Locations_Master_Read_All" ON public.locations FOR SELECT USING ((auth.role() = 'authenticated'::text));

--
-- Name: locations Locations_Master_Write_Manager; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Locations_Master_Write_Manager" ON public.locations USING ((EXISTS ( SELECT 1
   FROM public.memberships
  WHERE ((memberships.user_id = auth.uid()) AND (memberships.role ~~* ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))));

--
-- Name: cleaning_catalog Manager Catalog Access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Manager Catalog Access" ON public.cleaning_catalog USING (public.check_manager_access(org_id)) WITH CHECK (public.check_manager_access(org_id));

--
-- Name: cleaning_inventory Manager Inventory Access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Manager Inventory Access" ON public.cleaning_inventory USING (public.check_manager_access(org_id)) WITH CHECK (public.check_manager_access(org_id));

--
-- Name: property_checklists Manager Manage Checklists via Location; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Manager Manage Checklists via Location" ON public.property_checklists USING (public.can_manage_location(location_id)) WITH CHECK (public.can_manage_location(location_id));

--
-- Name: location_access Manager Manage Location Access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Manager Manage Location Access" ON public.location_access USING (public.check_location_manager(location_id)) WITH CHECK (public.check_location_manager(location_id));

--
-- Name: locations Manager_Full_Access_Master_Locations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Manager_Full_Access_Master_Locations" ON public.locations USING ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = locations.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))));

--
-- Name: fuel_logs Org isolation ALL for owners fuel_logs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Org isolation ALL for owners fuel_logs" ON public.fuel_logs TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = fuel_logs.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'coordinator'::text])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = fuel_logs.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'coordinator'::text]))))));

--
-- Name: locations Org isolation ALL for owners locations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Org isolation ALL for owners locations" ON public.locations TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = locations.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'coordinator'::text])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = locations.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'coordinator'::text]))))));

--
-- Name: staff_equipment Org isolation ALL for owners staff_equipment; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Org isolation ALL for owners staff_equipment" ON public.staff_equipment TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = staff_equipment.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'coordinator'::text])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = staff_equipment.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'coordinator'::text]))))));

--
-- Name: staff_financial_adjustments Org isolation ALL for owners staff_financial_adjustments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Org isolation ALL for owners staff_financial_adjustments" ON public.staff_financial_adjustments TO authenticated USING (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM (public.memberships m_employee
     JOIN public.memberships m_manager ON ((m_manager.org_id = m_employee.org_id)))
  WHERE ((m_employee.user_id = staff_financial_adjustments.user_id) AND (m_manager.user_id = auth.uid()) AND (m_manager.role = ANY (ARRAY['owner'::text, 'coordinator'::text]))))))) WITH CHECK (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM (public.memberships m_employee
     JOIN public.memberships m_manager ON ((m_manager.org_id = m_employee.org_id)))
  WHERE ((m_employee.user_id = staff_financial_adjustments.user_id) AND (m_manager.user_id = auth.uid()) AND (m_manager.role = ANY (ARRAY['owner'::text, 'coordinator'::text])))))));

--
-- Name: task_execution_logs Org isolation ALL for owners task_execution_logs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Org isolation ALL for owners task_execution_logs" ON public.task_execution_logs TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.cleaning_tasks ct
     JOIN public.memberships m ON ((m.org_id = ct.org_id)))
  WHERE ((ct.id = task_execution_logs.task_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'coordinator'::text])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (public.cleaning_tasks ct
     JOIN public.memberships m ON ((m.org_id = ct.org_id)))
  WHERE ((ct.id = task_execution_logs.task_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'coordinator'::text]))))));

--
-- Name: organizations Org members can read org settings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Org members can read org settings" ON public.organizations FOR SELECT USING ((id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid()))));

--
-- Name: applications Platform admin full access applications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Platform admin full access applications" ON public.applications TO authenticated USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

--
-- Name: offer_interactions Platform admin full access offer_interactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Platform admin full access offer_interactions" ON public.offer_interactions TO authenticated USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

--
-- Name: page_content Platform admin full access page_content; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Platform admin full access page_content" ON public.page_content TO authenticated USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

--
-- Name: pricing_plans Platform admin full access pricing_plans; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Platform admin full access pricing_plans" ON public.pricing_plans TO authenticated USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

--
-- Name: promo_codes Platform admin full access promo_codes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Platform admin full access promo_codes" ON public.promo_codes TO authenticated USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

--
-- Name: applications Public apps are viewable by everyone; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public apps are viewable by everyone" ON public.applications FOR SELECT USING ((is_active = true));

--
-- Name: applications Public can read active applications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can read active applications" ON public.applications FOR SELECT TO authenticated, anon USING ((COALESCE(is_active, true) = true));

--
-- Name: pricing_plans Public can read active pricing_plans; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can read active pricing_plans" ON public.pricing_plans FOR SELECT TO authenticated, anon USING ((is_active = true));

--
-- Name: page_content Public can read page content; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can read page content" ON public.page_content FOR SELECT TO authenticated, anon USING (true);

--
-- Name: legal_documents Public_read_active_documents; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public_read_active_documents" ON public.legal_documents FOR SELECT USING ((is_active = true));

--
-- Name: e_board_messages Publiczna widoczność aktywnych ogłoszeń; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Publiczna widoczność aktywnych ogłoszeń" ON public.e_board_messages FOR SELECT TO anon USING (((status = 'published'::public.eboard_msg_status) AND ((valid_until IS NULL) OR (valid_until > now()))));

--
-- Name: locations Read_All_Locations_Authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Read_All_Locations_Authenticated" ON public.locations FOR SELECT USING ((auth.role() = 'authenticated'::text));

--
-- Name: community_comments Residents insert comments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Residents insert comments" ON public.community_comments FOR INSERT WITH CHECK (((author_id = auth.uid()) AND (post_id IN ( SELECT community_board.id
   FROM public.community_board
  WHERE (community_board.location_id IN ( SELECT location_access.location_id
           FROM public.location_access
          WHERE (location_access.user_id = auth.uid())))))));

--
-- Name: community_comments Residents read comments for location posts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Residents read comments for location posts" ON public.community_comments FOR SELECT USING (((post_id IN ( SELECT community_board.id
   FROM public.community_board
  WHERE (community_board.location_id IN ( SELECT location_access.location_id
           FROM public.location_access
          WHERE (location_access.user_id = auth.uid()))))) AND (is_deleted = false)));

--
-- Name: community_comments Residents update/delete own comments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Residents update/delete own comments" ON public.community_comments FOR UPDATE USING ((author_id = auth.uid()));

--
-- Name: property_issues Residents view public issues; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Residents view public issues" ON public.property_issues FOR SELECT USING (((location_id IN ( SELECT location_access.location_id
   FROM public.location_access
  WHERE (location_access.user_id = auth.uid()))) AND ((is_public_broadcast = true) OR (category = 'Części wspólne'::text))));

--
-- Name: locations Secure Location View; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Secure Location View" ON public.locations FOR SELECT USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid()))));

--
-- Name: property_checklists Staff View Checklists; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Staff View Checklists" ON public.property_checklists FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.cleaning_locations cl
  WHERE ((cl.id = property_checklists.location_id) AND ((EXISTS ( SELECT 1
           FROM public.cleaning_tasks t
          WHERE ((t.assigned_staff_id = auth.uid()) AND (t.location_id = cl.id)))) OR (EXISTS ( SELECT 1
           FROM public.property_sections s
          WHERE ((s.assigned_staff_id = auth.uid()) AND (s.location_id = cl.id)))))))));

--
-- Name: cleaning_staff Universal Staff Visibility; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Universal Staff Visibility" ON public.cleaning_staff FOR SELECT USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid()))));

--
-- Name: property_inspections Users can access inspections for their locations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can access inspections for their locations" ON public.property_inspections USING ((location_id IN ( SELECT location_access.location_id
   FROM public.location_access
  WHERE (location_access.user_id = auth.uid()))));

--
-- Name: offer_interactions Users can insert own interactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert own interactions" ON public.offer_interactions FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));

--
-- Name: staff_financial_adjustments Users see own adjustments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users see own adjustments" ON public.staff_financial_adjustments FOR SELECT TO authenticated USING ((user_id = auth.uid()));

--
-- Name: property_issues Vendors can update delegated issues; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Vendors can update delegated issues" ON public.property_issues FOR UPDATE USING ((delegated_vendor_id IN ( SELECT vendor_partners.id
   FROM public.vendor_partners
  WHERE (vendor_partners.org_id = ( SELECT memberships.org_id
           FROM public.memberships
          WHERE (memberships.user_id = auth.uid())
         LIMIT 1))))) WITH CHECK ((delegated_vendor_id IN ( SELECT vendor_partners.id
   FROM public.vendor_partners
  WHERE (vendor_partners.org_id = ( SELECT memberships.org_id
           FROM public.memberships
          WHERE (memberships.user_id = auth.uid())
         LIMIT 1)))));

--
-- Name: property_issues Vendors can view delegated issues; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Vendors can view delegated issues" ON public.property_issues FOR SELECT USING ((delegated_vendor_id IN ( SELECT vendor_partners.id
   FROM public.vendor_partners
  WHERE (vendor_partners.org_id = ( SELECT memberships.org_id
           FROM public.memberships
          WHERE (memberships.user_id = auth.uid())
         LIMIT 1)))));

--
-- Name: cleaning_tasks cleaning_tasks_policy_final; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY cleaning_tasks_policy_final ON public.cleaning_tasks TO authenticated USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid())))) WITH CHECK ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid()))));

--
-- Name: companies companies_org_membership_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY companies_org_membership_all ON public.companies TO authenticated USING (((org_id IS NOT NULL) AND (org_id IN ( SELECT m.org_id
   FROM public.memberships m
  WHERE ((m.user_id = auth.uid()) AND (COALESCE(m.is_active, true) = true)))))) WITH CHECK (((org_id IS NOT NULL) AND (org_id IN ( SELECT m.org_id
   FROM public.memberships m
  WHERE ((m.user_id = auth.uid()) AND (COALESCE(m.is_active, true) = true))))));

--
-- Name: location_holidays location_holidays_delete_for_management; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY location_holidays_delete_for_management ON public.location_holidays FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = location_holidays.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))));

--
-- Name: location_holidays location_holidays_insert_for_management; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY location_holidays_insert_for_management ON public.location_holidays FOR INSERT TO authenticated WITH CHECK (((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = location_holidays.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))) AND ((location_id IS NULL) OR (EXISTS ( SELECT 1
   FROM (public.cleaning_locations cl
     JOIN public.memberships m ON ((m.org_id = cl.org_id)))
  WHERE ((cl.id = location_holidays.location_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))))));

--
-- Name: location_holidays location_holidays_select_for_management; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY location_holidays_select_for_management ON public.location_holidays FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = location_holidays.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))));

--
-- Name: location_holidays location_holidays_update_for_management; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY location_holidays_update_for_management ON public.location_holidays FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = location_holidays.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.memberships m
  WHERE ((m.org_id = location_holidays.org_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text]))))));

--
-- Name: cleaning_locations locations_final; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY locations_final ON public.cleaning_locations FOR SELECT TO authenticated USING (((public.is_manager_safe() AND (org_id = public.get_my_org_id_safe())) OR (id IN ( SELECT cleaning_tasks.location_id
   FROM public.cleaning_tasks
  WHERE (cleaning_tasks.assigned_staff_id = auth.uid())))));

--
-- Name: task_step_logs logs_final; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY logs_final ON public.task_step_logs TO authenticated USING ((task_id IN ( SELECT cleaning_tasks.id
   FROM public.cleaning_tasks))) WITH CHECK ((task_id IN ( SELECT cleaning_tasks.id
   FROM public.cleaning_tasks)));

--
-- Name: memberships memberships_final; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY memberships_final ON public.memberships FOR SELECT TO authenticated USING ((org_id = public.get_my_org_id_safe()));

--
-- Name: profiles profiles_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_select_own ON public.profiles FOR SELECT TO authenticated USING ((auth.uid() = id));

--
-- Name: profiles profiles_update_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE TO authenticated USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));

--
-- Name: property_contracts property_contracts_all_location_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_contracts_all_location_access ON public.property_contracts TO authenticated USING (public.user_has_location_access_docs(location_id)) WITH CHECK (public.user_has_location_access_docs(location_id));

--
-- Name: property_issues property_issues_all_for_management; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_issues_all_for_management ON public.property_issues TO authenticated USING (((org_id IS NOT NULL) AND public.is_management_role(org_id))) WITH CHECK (((org_id IS NOT NULL) AND public.is_management_role(org_id)));

--
-- Name: property_issues property_issues_insert_for_cleaners; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_issues_insert_for_cleaners ON public.property_issues FOR INSERT TO authenticated WITH CHECK (((reporter_id = auth.uid()) AND ((location_id IS NULL) OR ((location_id IN ( SELECT cleaning_tasks.location_id
   FROM public.cleaning_tasks
  WHERE ((cleaning_tasks.assigned_staff_id = auth.uid()) AND (cleaning_tasks.location_id IS NOT NULL)))) OR (location_id IN ( SELECT property_sections.location_id
   FROM public.property_sections
  WHERE ((property_sections.assigned_staff_id = auth.uid()) AND (property_sections.location_id IS NOT NULL))))) OR ((org_id IS NOT NULL) AND public.is_management_role(org_id)))));

--
-- Name: property_issues property_issues_select_for_cleaners; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_issues_select_for_cleaners ON public.property_issues FOR SELECT TO authenticated USING (((reporter_id = auth.uid()) OR ((location_id IS NOT NULL) AND ((location_id IN ( SELECT cleaning_tasks.location_id
   FROM public.cleaning_tasks
  WHERE ((cleaning_tasks.assigned_staff_id = auth.uid()) AND (cleaning_tasks.location_id IS NOT NULL)))) OR (location_id IN ( SELECT property_sections.location_id
   FROM public.property_sections
  WHERE ((property_sections.assigned_staff_id = auth.uid()) AND (property_sections.location_id IS NOT NULL))))))));

--
-- Name: property_issues property_issues_update_for_cleaners; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_issues_update_for_cleaners ON public.property_issues FOR UPDATE TO authenticated USING ((reporter_id = auth.uid())) WITH CHECK ((reporter_id = auth.uid()));

--
-- Name: property_policies property_policies_all_location_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_policies_all_location_access ON public.property_policies TO authenticated USING (public.user_has_location_access_docs(location_id)) WITH CHECK (public.user_has_location_access_docs(location_id));

--
-- Name: property_tasks property_tasks_delete_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_tasks_delete_access ON public.property_tasks FOR DELETE TO authenticated USING (public.property_task_user_has_access(location_id));

--
-- Name: property_tasks property_tasks_insert_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_tasks_insert_access ON public.property_tasks FOR INSERT TO authenticated WITH CHECK ((public.property_task_user_has_access(location_id) AND (created_by = auth.uid())));

--
-- Name: property_tasks property_tasks_select_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_tasks_select_access ON public.property_tasks FOR SELECT TO authenticated USING (public.property_task_user_has_access(location_id));

--
-- Name: property_tasks property_tasks_update_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY property_tasks_update_access ON public.property_tasks FOR UPDATE TO authenticated USING (public.property_task_user_has_access(location_id)) WITH CHECK (public.property_task_user_has_access(location_id));

--
-- Name: property_sections sections_final; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sections_final ON public.property_sections FOR SELECT TO authenticated USING ((location_id IN ( SELECT cleaning_locations.id
   FROM public.cleaning_locations)));

--
-- Name: task_comments task_comments_delete_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY task_comments_delete_access ON public.task_comments FOR DELETE TO authenticated USING (public.property_task_user_has_access(public.property_task_location_id(task_id)));

--
-- Name: task_comments task_comments_insert_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY task_comments_insert_access ON public.task_comments FOR INSERT TO authenticated WITH CHECK (((author_id = auth.uid()) AND public.property_task_user_has_access(public.property_task_location_id(task_id))));

--
-- Name: task_comments task_comments_select_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY task_comments_select_access ON public.task_comments FOR SELECT TO authenticated USING (public.property_task_user_has_access(public.property_task_location_id(task_id)));

--
-- Name: task_comments task_comments_update_access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY task_comments_update_access ON public.task_comments FOR UPDATE TO authenticated USING (public.property_task_user_has_access(public.property_task_location_id(task_id))) WITH CHECK (public.property_task_user_has_access(public.property_task_location_id(task_id)));

--
-- Name: task_execution_logs task_execution_logs_insert_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY task_execution_logs_insert_own ON public.task_execution_logs FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));

--
-- Name: task_execution_logs task_execution_logs_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY task_execution_logs_select_own ON public.task_execution_logs FOR SELECT TO authenticated USING ((user_id = auth.uid()));

--
-- Name: task_step_logs task_step_logs_insert_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY task_step_logs_insert_own ON public.task_step_logs FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));

--
-- Name: task_step_logs task_step_logs_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY task_step_logs_select_own ON public.task_step_logs FOR SELECT TO authenticated USING ((user_id = auth.uid()));

--
-- Name: cleaning_tasks worker_tasks_master_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY worker_tasks_master_policy ON public.cleaning_tasks TO authenticated USING ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid())))) WITH CHECK ((org_id IN ( SELECT memberships.org_id
   FROM public.memberships
  WHERE (memberships.user_id = auth.uid()))));

--
-- Name: POLICY companies_org_membership_all ON companies; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY companies_org_membership_all ON public.companies IS 'Authenticated users may read/write companies only for orgs they belong to (active membership).';

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;

--
-- Name: FUNCTION box2d_in(cstring); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box2d_in(cstring) TO postgres;
GRANT ALL ON FUNCTION public.box2d_in(cstring) TO anon;
GRANT ALL ON FUNCTION public.box2d_in(cstring) TO authenticated;
GRANT ALL ON FUNCTION public.box2d_in(cstring) TO service_role;

--
-- Name: FUNCTION box2d_out(public.box2d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO postgres;
GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO anon;
GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO authenticated;
GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO service_role;

--
-- Name: FUNCTION box2df_in(cstring); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box2df_in(cstring) TO postgres;
GRANT ALL ON FUNCTION public.box2df_in(cstring) TO anon;
GRANT ALL ON FUNCTION public.box2df_in(cstring) TO authenticated;
GRANT ALL ON FUNCTION public.box2df_in(cstring) TO service_role;

--
-- Name: FUNCTION box2df_out(public.box2df); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO postgres;
GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO anon;
GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO authenticated;
GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO service_role;

--
-- Name: FUNCTION box3d_in(cstring); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box3d_in(cstring) TO postgres;
GRANT ALL ON FUNCTION public.box3d_in(cstring) TO anon;
GRANT ALL ON FUNCTION public.box3d_in(cstring) TO authenticated;
GRANT ALL ON FUNCTION public.box3d_in(cstring) TO service_role;

--
-- Name: FUNCTION box3d_out(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO service_role;

--
-- Name: TYPE company_category; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.company_category TO authenticated;

--
-- Name: FUNCTION geography_analyze(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_analyze(internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_analyze(internal) TO anon;
GRANT ALL ON FUNCTION public.geography_analyze(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_analyze(internal) TO service_role;

--
-- Name: FUNCTION geography_in(cstring, oid, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO postgres;
GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO anon;
GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO authenticated;
GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO service_role;

--
-- Name: FUNCTION geography_out(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_out(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_out(public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_out(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_out(public.geography) TO service_role;

--
-- Name: FUNCTION geography_recv(internal, oid, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO postgres;
GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO anon;
GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO authenticated;
GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO service_role;

--
-- Name: FUNCTION geography_send(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_send(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_send(public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_send(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_send(public.geography) TO service_role;

--
-- Name: FUNCTION geography_typmod_in(cstring[]); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO postgres;
GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO anon;
GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO authenticated;
GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO service_role;

--
-- Name: FUNCTION geography_typmod_out(integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO postgres;
GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO anon;
GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO authenticated;
GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO service_role;

--
-- Name: FUNCTION geometry_analyze(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO service_role;

--
-- Name: FUNCTION geometry_in(cstring); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_in(cstring) TO postgres;
GRANT ALL ON FUNCTION public.geometry_in(cstring) TO anon;
GRANT ALL ON FUNCTION public.geometry_in(cstring) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_in(cstring) TO service_role;

--
-- Name: FUNCTION geometry_out(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_recv(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_recv(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_recv(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_recv(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_recv(internal) TO service_role;

--
-- Name: FUNCTION geometry_send(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_typmod_in(cstring[]); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO postgres;
GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO anon;
GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO service_role;

--
-- Name: FUNCTION geometry_typmod_out(integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO postgres;
GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO anon;
GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO service_role;

--
-- Name: FUNCTION gidx_in(cstring); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gidx_in(cstring) TO postgres;
GRANT ALL ON FUNCTION public.gidx_in(cstring) TO anon;
GRANT ALL ON FUNCTION public.gidx_in(cstring) TO authenticated;
GRANT ALL ON FUNCTION public.gidx_in(cstring) TO service_role;

--
-- Name: FUNCTION gidx_out(public.gidx); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO postgres;
GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO anon;
GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO authenticated;
GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO service_role;

--
-- Name: TYPE property_contract_type; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.property_contract_type TO authenticated;

--
-- Name: TYPE property_task_priority; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.property_task_priority TO authenticated;

--
-- Name: TYPE property_task_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.property_task_status TO authenticated;

--
-- Name: TYPE property_task_visibility; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.property_task_visibility TO authenticated;

--
-- Name: FUNCTION spheroid_in(cstring); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO postgres;
GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO anon;
GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO authenticated;
GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO service_role;

--
-- Name: FUNCTION spheroid_out(public.spheroid); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO postgres;
GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO anon;
GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO authenticated;
GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO service_role;

--
-- Name: FUNCTION box3d(public.box2d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box3d(public.box2d) TO postgres;
GRANT ALL ON FUNCTION public.box3d(public.box2d) TO anon;
GRANT ALL ON FUNCTION public.box3d(public.box2d) TO authenticated;
GRANT ALL ON FUNCTION public.box3d(public.box2d) TO service_role;

--
-- Name: FUNCTION geometry(public.box2d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(public.box2d) TO postgres;
GRANT ALL ON FUNCTION public.geometry(public.box2d) TO anon;
GRANT ALL ON FUNCTION public.geometry(public.box2d) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(public.box2d) TO service_role;

--
-- Name: FUNCTION box(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.box(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.box(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.box(public.box3d) TO service_role;

--
-- Name: FUNCTION box2d(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box2d(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.box2d(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.box2d(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.box2d(public.box3d) TO service_role;

--
-- Name: FUNCTION geometry(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.geometry(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.geometry(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(public.box3d) TO service_role;

--
-- Name: FUNCTION geography(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography(bytea) TO postgres;
GRANT ALL ON FUNCTION public.geography(bytea) TO anon;
GRANT ALL ON FUNCTION public.geography(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.geography(bytea) TO service_role;

--
-- Name: FUNCTION geometry(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(bytea) TO postgres;
GRANT ALL ON FUNCTION public.geometry(bytea) TO anon;
GRANT ALL ON FUNCTION public.geometry(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(bytea) TO service_role;

--
-- Name: FUNCTION bytea(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.bytea(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.bytea(public.geography) TO anon;
GRANT ALL ON FUNCTION public.bytea(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.bytea(public.geography) TO service_role;

--
-- Name: FUNCTION geography(public.geography, integer, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO postgres;
GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO anon;
GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO service_role;

--
-- Name: FUNCTION geometry(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geometry(public.geography) TO anon;
GRANT ALL ON FUNCTION public.geometry(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(public.geography) TO service_role;

--
-- Name: FUNCTION box(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.box(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.box(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.box(public.geometry) TO service_role;

--
-- Name: FUNCTION box2d(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box2d(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.box2d(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.box2d(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.box2d(public.geometry) TO service_role;

--
-- Name: FUNCTION box3d(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box3d(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.box3d(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.box3d(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.box3d(public.geometry) TO service_role;

--
-- Name: FUNCTION bytea(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.bytea(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.bytea(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.bytea(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.bytea(public.geometry) TO service_role;

--
-- Name: FUNCTION geography(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geography(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geography(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geography(public.geometry) TO service_role;

--
-- Name: FUNCTION geometry(public.geometry, integer, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO postgres;
GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO anon;
GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO service_role;

--
-- Name: FUNCTION "json"(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public."json"(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public."json"(public.geometry) TO anon;
GRANT ALL ON FUNCTION public."json"(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public."json"(public.geometry) TO service_role;

--
-- Name: FUNCTION jsonb(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO service_role;

--
-- Name: FUNCTION path(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.path(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.path(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.path(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.path(public.geometry) TO service_role;

--
-- Name: FUNCTION point(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.point(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.point(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.point(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.point(public.geometry) TO service_role;

--
-- Name: FUNCTION polygon(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.polygon(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.polygon(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.polygon(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.polygon(public.geometry) TO service_role;

--
-- Name: FUNCTION text(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.text(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.text(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.text(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.text(public.geometry) TO service_role;

--
-- Name: FUNCTION geometry(path); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(path) TO postgres;
GRANT ALL ON FUNCTION public.geometry(path) TO anon;
GRANT ALL ON FUNCTION public.geometry(path) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(path) TO service_role;

--
-- Name: FUNCTION geometry(point); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(point) TO postgres;
GRANT ALL ON FUNCTION public.geometry(point) TO anon;
GRANT ALL ON FUNCTION public.geometry(point) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(point) TO service_role;

--
-- Name: FUNCTION geometry(polygon); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(polygon) TO postgres;
GRANT ALL ON FUNCTION public.geometry(polygon) TO anon;
GRANT ALL ON FUNCTION public.geometry(polygon) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(polygon) TO service_role;

--
-- Name: FUNCTION geometry(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry(text) TO postgres;
GRANT ALL ON FUNCTION public.geometry(text) TO anon;
GRANT ALL ON FUNCTION public.geometry(text) TO authenticated;
GRANT ALL ON FUNCTION public.geometry(text) TO service_role;

--
-- Name: FUNCTION pg_reload_conf(); Type: ACL; Schema: pg_catalog; Owner: supabase_admin
--

GRANT ALL ON FUNCTION pg_catalog.pg_reload_conf() TO postgres WITH GRANT OPTION;

--
-- Name: FUNCTION _postgis_deprecate(oldname text, newname text, version text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO postgres;
GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO anon;
GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO authenticated;
GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO service_role;

--
-- Name: FUNCTION _postgis_index_extent(tbl regclass, col text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO postgres;
GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO anon;
GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO authenticated;
GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO service_role;

--
-- Name: FUNCTION _postgis_join_selectivity(regclass, text, regclass, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO postgres;
GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO anon;
GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO authenticated;
GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO service_role;

--
-- Name: FUNCTION _postgis_pgsql_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO postgres;
GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO anon;
GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO authenticated;
GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO service_role;

--
-- Name: FUNCTION _postgis_scripts_pgsql_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO postgres;
GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO anon;
GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO authenticated;
GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO service_role;

--
-- Name: FUNCTION _postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO postgres;
GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO anon;
GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO authenticated;
GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO service_role;

--
-- Name: FUNCTION _postgis_stats(tbl regclass, att_name text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO postgres;
GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO anon;
GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO authenticated;
GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO service_role;

--
-- Name: FUNCTION _st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION _st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION _st_3dintersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_asgml(integer, public.geometry, integer, integer, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO postgres;
GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO anon;
GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO authenticated;
GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO service_role;

--
-- Name: FUNCTION _st_asx3d(integer, public.geometry, integer, integer, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO postgres;
GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO anon;
GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO authenticated;
GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO service_role;

--
-- Name: FUNCTION _st_bestsrid(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO postgres;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO anon;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO service_role;

--
-- Name: FUNCTION _st_bestsrid(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION _st_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_containsproperly(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_coveredby(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO postgres;
GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO anon;
GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO authenticated;
GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO service_role;

--
-- Name: FUNCTION _st_coveredby(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_covers(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO postgres;
GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO anon;
GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO authenticated;
GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO service_role;

--
-- Name: FUNCTION _st_covers(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_crosses(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION _st_distancetree(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION _st_distancetree(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO postgres;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO anon;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO authenticated;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO service_role;

--
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO postgres;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO anon;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO authenticated;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO service_role;

--
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO postgres;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO anon;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO authenticated;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO service_role;

--
-- Name: FUNCTION _st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION _st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO postgres;
GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO anon;
GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO authenticated;
GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO service_role;

--
-- Name: FUNCTION _st_dwithinuncached(public.geography, public.geography, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO postgres;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO anon;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO authenticated;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO service_role;

--
-- Name: FUNCTION _st_dwithinuncached(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO postgres;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO anon;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO authenticated;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO service_role;

--
-- Name: FUNCTION _st_equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_expand(public.geography, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO postgres;
GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO anon;
GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO authenticated;
GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO service_role;

--
-- Name: FUNCTION _st_geomfromgml(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO postgres;
GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO anon;
GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO service_role;

--
-- Name: FUNCTION _st_intersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_linecrossingdirection(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_longestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_maxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_orderingequals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_pointoutside(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO postgres;
GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO anon;
GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO service_role;

--
-- Name: FUNCTION _st_sortablehash(geom public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO service_role;

--
-- Name: FUNCTION _st_touches(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION _st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO postgres;
GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO anon;
GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO authenticated;
GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO service_role;

--
-- Name: FUNCTION _st_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION addauth(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.addauth(text) TO postgres;
GRANT ALL ON FUNCTION public.addauth(text) TO anon;
GRANT ALL ON FUNCTION public.addauth(text) TO authenticated;
GRANT ALL ON FUNCTION public.addauth(text) TO service_role;

--
-- Name: FUNCTION addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO postgres;
GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO anon;
GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO authenticated;
GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO service_role;

--
-- Name: FUNCTION addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO postgres;
GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO anon;
GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO authenticated;
GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO service_role;

--
-- Name: FUNCTION addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO postgres;
GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO anon;
GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO authenticated;
GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO service_role;

--
-- Name: FUNCTION box3dtobox(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO service_role;

--
-- Name: FUNCTION can_manage_location(target_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.can_manage_location(target_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.can_manage_location(target_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.can_manage_location(target_location_id uuid) TO service_role;

--
-- Name: FUNCTION check_is_admin(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_is_admin() TO anon;
GRANT ALL ON FUNCTION public.check_is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.check_is_admin() TO service_role;

--
-- Name: FUNCTION check_location_manager(target_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_location_manager(target_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.check_location_manager(target_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.check_location_manager(target_location_id uuid) TO service_role;

--
-- Name: FUNCTION check_location_proximity(p_location_id uuid, p_user_latitude double precision, p_user_longitude double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_location_proximity(p_location_id uuid, p_user_latitude double precision, p_user_longitude double precision) TO anon;
GRANT ALL ON FUNCTION public.check_location_proximity(p_location_id uuid, p_user_latitude double precision, p_user_longitude double precision) TO authenticated;
GRANT ALL ON FUNCTION public.check_location_proximity(p_location_id uuid, p_user_latitude double precision, p_user_longitude double precision) TO service_role;

--
-- Name: FUNCTION check_manager_access(target_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_manager_access(target_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.check_manager_access(target_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.check_manager_access(target_org_id uuid) TO service_role;

--
-- Name: FUNCTION check_org_access(target_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_org_access(target_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.check_org_access(target_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.check_org_access(target_org_id uuid) TO service_role;

--
-- Name: FUNCTION check_slug_available(p_slug text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_slug_available(p_slug text) TO anon;
GRANT ALL ON FUNCTION public.check_slug_available(p_slug text) TO authenticated;
GRANT ALL ON FUNCTION public.check_slug_available(p_slug text) TO service_role;

--
-- Name: FUNCTION check_user_belongs_to_org(p_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_user_belongs_to_org(p_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.check_user_belongs_to_org(p_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.check_user_belongs_to_org(p_org_id uuid) TO service_role;

--
-- Name: FUNCTION checkauth(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.checkauth(text, text) TO postgres;
GRANT ALL ON FUNCTION public.checkauth(text, text) TO anon;
GRANT ALL ON FUNCTION public.checkauth(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.checkauth(text, text) TO service_role;

--
-- Name: FUNCTION checkauth(text, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO postgres;
GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO anon;
GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO service_role;

--
-- Name: FUNCTION checkauthtrigger(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.checkauthtrigger() TO postgres;
GRANT ALL ON FUNCTION public.checkauthtrigger() TO anon;
GRANT ALL ON FUNCTION public.checkauthtrigger() TO authenticated;
GRANT ALL ON FUNCTION public.checkauthtrigger() TO service_role;

--
-- Name: FUNCTION complete_task(p_task_id uuid, p_photo_urls text[], p_notes text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.complete_task(p_task_id uuid, p_photo_urls text[], p_notes text) TO anon;
GRANT ALL ON FUNCTION public.complete_task(p_task_id uuid, p_photo_urls text[], p_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.complete_task(p_task_id uuid, p_photo_urls text[], p_notes text) TO service_role;

--
-- Name: FUNCTION contains_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO postgres;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO anon;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO authenticated;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO service_role;

--
-- Name: FUNCTION contains_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO service_role;

--
-- Name: FUNCTION contains_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO postgres;
GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO anon;
GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO authenticated;
GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO service_role;

--
-- Name: FUNCTION disablelongtransactions(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.disablelongtransactions() TO postgres;
GRANT ALL ON FUNCTION public.disablelongtransactions() TO anon;
GRANT ALL ON FUNCTION public.disablelongtransactions() TO authenticated;
GRANT ALL ON FUNCTION public.disablelongtransactions() TO service_role;

--
-- Name: FUNCTION dropgeometrycolumn(table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO postgres;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO anon;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO authenticated;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO service_role;

--
-- Name: FUNCTION dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO postgres;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO anon;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO authenticated;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO service_role;

--
-- Name: FUNCTION dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO postgres;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO anon;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO authenticated;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO service_role;

--
-- Name: FUNCTION dropgeometrytable(table_name character varying); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO postgres;
GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO anon;
GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO authenticated;
GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO service_role;

--
-- Name: FUNCTION dropgeometrytable(schema_name character varying, table_name character varying); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO postgres;
GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO anon;
GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO authenticated;
GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO service_role;

--
-- Name: FUNCTION dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO postgres;
GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO anon;
GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO authenticated;
GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO service_role;

--
-- Name: FUNCTION enablelongtransactions(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.enablelongtransactions() TO postgres;
GRANT ALL ON FUNCTION public.enablelongtransactions() TO anon;
GRANT ALL ON FUNCTION public.enablelongtransactions() TO authenticated;
GRANT ALL ON FUNCTION public.enablelongtransactions() TO service_role;

--
-- Name: FUNCTION enforce_company_matches_location_org(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.enforce_company_matches_location_org() TO anon;
GRANT ALL ON FUNCTION public.enforce_company_matches_location_org() TO authenticated;
GRANT ALL ON FUNCTION public.enforce_company_matches_location_org() TO service_role;

--
-- Name: FUNCTION equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION find_srid(character varying, character varying, character varying); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO postgres;
GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO anon;
GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO authenticated;
GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO service_role;

--
-- Name: FUNCTION geog_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO service_role;

--
-- Name: FUNCTION geography_cmp(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION geography_distance_knn(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION geography_eq(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION geography_ge(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION geography_gist_compress(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO anon;
GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO service_role;

--
-- Name: FUNCTION geography_gist_consistent(internal, public.geography, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO postgres;
GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO anon;
GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO service_role;

--
-- Name: FUNCTION geography_gist_decompress(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO anon;
GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO service_role;

--
-- Name: FUNCTION geography_gist_distance(internal, public.geography, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO postgres;
GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO anon;
GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO service_role;

--
-- Name: FUNCTION geography_gist_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO service_role;

--
-- Name: FUNCTION geography_gist_picksplit(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO service_role;

--
-- Name: FUNCTION geography_gist_same(public.box2d, public.box2d, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO service_role;

--
-- Name: FUNCTION geography_gist_union(bytea, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO service_role;

--
-- Name: FUNCTION geography_gt(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION geography_le(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION geography_lt(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION geography_overlaps(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION geography_spgist_choose_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geography_spgist_compress_nd(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO anon;
GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO service_role;

--
-- Name: FUNCTION geography_spgist_config_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geography_spgist_inner_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geography_spgist_leaf_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geography_spgist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geom2d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO service_role;

--
-- Name: FUNCTION geom3d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO service_role;

--
-- Name: FUNCTION geom4d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_above(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_below(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_cmp(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_contained_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_contains_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_contains_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_distance_box(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_distance_centroid_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_distance_cpa(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_eq(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_ge(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_gist_compress_2d(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_compress_nd(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_consistent_2d(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO service_role;

--
-- Name: FUNCTION geometry_gist_consistent_nd(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO service_role;

--
-- Name: FUNCTION geometry_gist_decompress_2d(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_decompress_nd(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_distance_2d(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO service_role;

--
-- Name: FUNCTION geometry_gist_distance_nd(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO service_role;

--
-- Name: FUNCTION geometry_gist_penalty_2d(internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_penalty_nd(internal, internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_picksplit_2d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_same_nd(public.geometry, public.geometry, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_sortsupport_2d(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_union_2d(bytea, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO service_role;

--
-- Name: FUNCTION geometry_gist_union_nd(bytea, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO service_role;

--
-- Name: FUNCTION geometry_gt(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_hash(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_le(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_left(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_lt(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_overabove(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_overbelow(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_overlaps_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_overleft(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_overright(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_right(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_same(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_same_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_same_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_sortsupport(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_choose_2d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_choose_3d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_choose_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_compress_2d(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_compress_3d(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_compress_nd(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_config_2d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_config_3d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_config_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_inner_consistent_2d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_inner_consistent_3d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_inner_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_leaf_consistent_2d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_leaf_consistent_3d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_leaf_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_picksplit_2d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_picksplit_3d(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_spgist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO service_role;

--
-- Name: FUNCTION geometry_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION geometry_within_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION geometrytype(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO anon;
GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO service_role;

--
-- Name: FUNCTION geometrytype(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO service_role;

--
-- Name: FUNCTION geomfromewkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO service_role;

--
-- Name: FUNCTION geomfromewkt(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.geomfromewkt(text) TO postgres;
GRANT ALL ON FUNCTION public.geomfromewkt(text) TO anon;
GRANT ALL ON FUNCTION public.geomfromewkt(text) TO authenticated;
GRANT ALL ON FUNCTION public.geomfromewkt(text) TO service_role;

--
-- Name: FUNCTION get_auth_org_ids(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_auth_org_ids() TO anon;
GRANT ALL ON FUNCTION public.get_auth_org_ids() TO authenticated;
GRANT ALL ON FUNCTION public.get_auth_org_ids() TO service_role;

--
-- Name: FUNCTION get_fleet_analytics(p_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_fleet_analytics(p_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_fleet_analytics(p_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_fleet_analytics(p_org_id uuid) TO service_role;

--
-- Name: FUNCTION get_location_org_id_safe(target_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_location_org_id_safe(target_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_location_org_id_safe(target_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_location_org_id_safe(target_location_id uuid) TO service_role;

--
-- Name: FUNCTION get_my_claims(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_claims() TO anon;
GRANT ALL ON FUNCTION public.get_my_claims() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_claims() TO service_role;

--
-- Name: FUNCTION get_my_org_and_role(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_org_and_role() TO anon;
GRANT ALL ON FUNCTION public.get_my_org_and_role() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_org_and_role() TO service_role;

--
-- Name: FUNCTION get_my_org_id_safe(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_org_id_safe() TO anon;
GRANT ALL ON FUNCTION public.get_my_org_id_safe() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_org_id_safe() TO service_role;

--
-- Name: FUNCTION get_my_org_ids(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_org_ids() TO anon;
GRANT ALL ON FUNCTION public.get_my_org_ids() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_org_ids() TO service_role;

--
-- Name: FUNCTION get_my_org_ids_safe(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_org_ids_safe() TO anon;
GRANT ALL ON FUNCTION public.get_my_org_ids_safe() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_org_ids_safe() TO service_role;

--
-- Name: FUNCTION get_my_orgs(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_orgs() TO anon;
GRANT ALL ON FUNCTION public.get_my_orgs() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_orgs() TO service_role;

--
-- Name: FUNCTION get_my_orgs_safe(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_orgs_safe() TO anon;
GRANT ALL ON FUNCTION public.get_my_orgs_safe() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_orgs_safe() TO service_role;

--
-- Name: FUNCTION get_profile_by_email(target_email text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_profile_by_email(target_email text) TO anon;
GRANT ALL ON FUNCTION public.get_profile_by_email(target_email text) TO authenticated;
GRANT ALL ON FUNCTION public.get_profile_by_email(target_email text) TO service_role;

--
-- Name: FUNCTION get_proj4_from_srid(integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO postgres;
GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO anon;
GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO service_role;

--
-- Name: FUNCTION get_property_tasks_with_comment_counts(p_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_property_tasks_with_comment_counts(p_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_property_tasks_with_comment_counts(p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_property_tasks_with_comment_counts(p_location_id uuid) TO service_role;

--
-- Name: FUNCTION get_user_highest_role(p_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_user_highest_role(p_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_user_highest_role(p_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_highest_role(p_org_id uuid) TO service_role;

--
-- Name: FUNCTION gettransactionid(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gettransactionid() TO postgres;
GRANT ALL ON FUNCTION public.gettransactionid() TO anon;
GRANT ALL ON FUNCTION public.gettransactionid() TO authenticated;
GRANT ALL ON FUNCTION public.gettransactionid() TO service_role;

--
-- Name: FUNCTION gserialized_gist_joinsel_2d(internal, oid, internal, smallint); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO postgres;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO anon;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO authenticated;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO service_role;

--
-- Name: FUNCTION gserialized_gist_joinsel_nd(internal, oid, internal, smallint); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO postgres;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO anon;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO authenticated;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO service_role;

--
-- Name: FUNCTION gserialized_gist_sel_2d(internal, oid, internal, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO postgres;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO anon;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO authenticated;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO service_role;

--
-- Name: FUNCTION gserialized_gist_sel_nd(internal, oid, internal, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO postgres;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO anon;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO authenticated;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO service_role;

--
-- Name: FUNCTION handle_updated_at(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_updated_at() TO anon;
GRANT ALL ON FUNCTION public.handle_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.handle_updated_at() TO service_role;

--
-- Name: FUNCTION has_location_access(target_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.has_location_access(target_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.has_location_access(target_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.has_location_access(target_location_id uuid) TO service_role;

--
-- Name: FUNCTION has_staff_access_safe(target_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.has_staff_access_safe(target_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.has_staff_access_safe(target_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.has_staff_access_safe(target_location_id uuid) TO service_role;

--
-- Name: FUNCTION is_admin_safe(target_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_admin_safe(target_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.is_admin_safe(target_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.is_admin_safe(target_org_id uuid) TO service_role;

--
-- Name: FUNCTION is_contained_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO postgres;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO anon;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO authenticated;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO service_role;

--
-- Name: FUNCTION is_contained_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO service_role;

--
-- Name: FUNCTION is_contained_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO postgres;
GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO anon;
GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO authenticated;
GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO service_role;

--
-- Name: FUNCTION is_management_role(target_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_management_role(target_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.is_management_role(target_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.is_management_role(target_org_id uuid) TO service_role;

--
-- Name: FUNCTION is_manager(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_manager() TO anon;
GRANT ALL ON FUNCTION public.is_manager() TO authenticated;
GRANT ALL ON FUNCTION public.is_manager() TO service_role;

--
-- Name: FUNCTION is_manager_safe(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_manager_safe() TO anon;
GRANT ALL ON FUNCTION public.is_manager_safe() TO authenticated;
GRANT ALL ON FUNCTION public.is_manager_safe() TO service_role;

--
-- Name: FUNCTION is_org_manager(target_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_org_manager(target_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.is_org_manager(target_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.is_org_manager(target_org_id uuid) TO service_role;

--
-- Name: FUNCTION is_org_manager_safe(target_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_org_manager_safe(target_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.is_org_manager_safe(target_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.is_org_manager_safe(target_org_id uuid) TO service_role;

--
-- Name: FUNCTION is_org_member(target_org_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_org_member(target_org_id uuid) TO anon;
GRANT ALL ON FUNCTION public.is_org_member(target_org_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.is_org_member(target_org_id uuid) TO service_role;

--
-- Name: FUNCTION is_platform_admin(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_platform_admin() TO anon;
GRANT ALL ON FUNCTION public.is_platform_admin() TO authenticated;
GRANT ALL ON FUNCTION public.is_platform_admin() TO service_role;

--
-- Name: FUNCTION link_user_to_org(target_user_id uuid, target_org_id uuid, target_role text, target_full_name text, target_email text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.link_user_to_org(target_user_id uuid, target_org_id uuid, target_role text, target_full_name text, target_email text) TO anon;
GRANT ALL ON FUNCTION public.link_user_to_org(target_user_id uuid, target_org_id uuid, target_role text, target_full_name text, target_email text) TO authenticated;
GRANT ALL ON FUNCTION public.link_user_to_org(target_user_id uuid, target_org_id uuid, target_role text, target_full_name text, target_email text) TO service_role;

--
-- Name: FUNCTION lockrow(text, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO postgres;
GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO anon;
GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO service_role;

--
-- Name: FUNCTION lockrow(text, text, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO postgres;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO anon;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO service_role;

--
-- Name: FUNCTION lockrow(text, text, text, timestamp without time zone); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO postgres;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO anon;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO authenticated;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO service_role;

--
-- Name: FUNCTION lockrow(text, text, text, text, timestamp without time zone); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO postgres;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO anon;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO authenticated;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO service_role;

--
-- Name: FUNCTION log_rate_changes(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.log_rate_changes() TO anon;
GRANT ALL ON FUNCTION public.log_rate_changes() TO authenticated;
GRANT ALL ON FUNCTION public.log_rate_changes() TO service_role;

--
-- Name: FUNCTION longtransactionsenabled(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.longtransactionsenabled() TO postgres;
GRANT ALL ON FUNCTION public.longtransactionsenabled() TO anon;
GRANT ALL ON FUNCTION public.longtransactionsenabled() TO authenticated;
GRANT ALL ON FUNCTION public.longtransactionsenabled() TO service_role;

--
-- Name: FUNCTION overlaps_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO anon;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO service_role;

--
-- Name: FUNCTION overlaps_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO service_role;

--
-- Name: FUNCTION overlaps_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO anon;
GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO service_role;

--
-- Name: FUNCTION overlaps_geog(public.geography, public.gidx); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO anon;
GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO service_role;

--
-- Name: FUNCTION overlaps_geog(public.gidx, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO anon;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO service_role;

--
-- Name: FUNCTION overlaps_geog(public.gidx, public.gidx); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO anon;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO service_role;

--
-- Name: FUNCTION overlaps_nd(public.geometry, public.gidx); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO anon;
GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO service_role;

--
-- Name: FUNCTION overlaps_nd(public.gidx, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO service_role;

--
-- Name: FUNCTION overlaps_nd(public.gidx, public.gidx); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO postgres;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO anon;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO authenticated;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO service_role;

--
-- Name: FUNCTION pgis_asflatgeobuf_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO anon;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO service_role;

--
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO anon;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO service_role;

--
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO anon;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO service_role;

--
-- Name: FUNCTION pgis_asgeobuf_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_asgeobuf_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO anon;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO service_role;

--
-- Name: FUNCTION pgis_asgeobuf_transfn(internal, anyelement, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO anon;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_combinefn(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_deserialfn(bytea, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_serialfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO service_role;

--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO postgres;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO anon;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO service_role;

--
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO service_role;

--
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO service_role;

--
-- Name: FUNCTION pgis_geometry_clusterintersecting_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_clusterwithin_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_collect_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_makeline_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_polygonize_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_union_parallel_combinefn(internal, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_union_parallel_deserialfn(bytea, internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_union_parallel_finalfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_union_parallel_serialfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO service_role;

--
-- Name: FUNCTION pgis_geometry_union_parallel_transfn(internal, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO service_role;

--
-- Name: FUNCTION pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION populate_geometry_columns(use_typmod boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO postgres;
GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO anon;
GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO authenticated;
GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO service_role;

--
-- Name: FUNCTION populate_geometry_columns(tbl_oid oid, use_typmod boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO postgres;
GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO anon;
GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO authenticated;
GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO service_role;

--
-- Name: FUNCTION postgis_addbbox(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO service_role;

--
-- Name: FUNCTION postgis_cache_bbox(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO postgres;
GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO anon;
GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO service_role;

--
-- Name: FUNCTION postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO postgres;
GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO anon;
GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO service_role;

--
-- Name: FUNCTION postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO postgres;
GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO anon;
GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO service_role;

--
-- Name: FUNCTION postgis_constraint_type(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO postgres;
GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO anon;
GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO service_role;

--
-- Name: FUNCTION postgis_dropbbox(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO service_role;

--
-- Name: FUNCTION postgis_extensions_upgrade(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_extensions_upgrade() TO postgres;
GRANT ALL ON FUNCTION public.postgis_extensions_upgrade() TO anon;
GRANT ALL ON FUNCTION public.postgis_extensions_upgrade() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_extensions_upgrade() TO service_role;

--
-- Name: FUNCTION postgis_full_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_full_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_full_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_full_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_full_version() TO service_role;

--
-- Name: FUNCTION postgis_geos_noop(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO service_role;

--
-- Name: FUNCTION postgis_geos_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_geos_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_geos_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_geos_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_geos_version() TO service_role;

--
-- Name: FUNCTION postgis_getbbox(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO service_role;

--
-- Name: FUNCTION postgis_hasbbox(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO service_role;

--
-- Name: FUNCTION postgis_index_supportfn(internal); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO postgres;
GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO anon;
GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO service_role;

--
-- Name: FUNCTION postgis_lib_build_date(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO postgres;
GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO anon;
GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO service_role;

--
-- Name: FUNCTION postgis_lib_revision(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_lib_revision() TO postgres;
GRANT ALL ON FUNCTION public.postgis_lib_revision() TO anon;
GRANT ALL ON FUNCTION public.postgis_lib_revision() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_lib_revision() TO service_role;

--
-- Name: FUNCTION postgis_lib_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_lib_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_lib_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_lib_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_lib_version() TO service_role;

--
-- Name: FUNCTION postgis_libjson_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_libjson_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_libjson_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_libjson_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_libjson_version() TO service_role;

--
-- Name: FUNCTION postgis_liblwgeom_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO service_role;

--
-- Name: FUNCTION postgis_libprotobuf_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO service_role;

--
-- Name: FUNCTION postgis_libxml_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_libxml_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_libxml_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_libxml_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_libxml_version() TO service_role;

--
-- Name: FUNCTION postgis_noop(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO service_role;

--
-- Name: FUNCTION postgis_proj_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_proj_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_proj_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_proj_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_proj_version() TO service_role;

--
-- Name: FUNCTION postgis_scripts_build_date(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO postgres;
GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO anon;
GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO service_role;

--
-- Name: FUNCTION postgis_scripts_installed(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO postgres;
GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO anon;
GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO service_role;

--
-- Name: FUNCTION postgis_scripts_released(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_scripts_released() TO postgres;
GRANT ALL ON FUNCTION public.postgis_scripts_released() TO anon;
GRANT ALL ON FUNCTION public.postgis_scripts_released() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_scripts_released() TO service_role;

--
-- Name: FUNCTION postgis_svn_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_svn_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_svn_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_svn_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_svn_version() TO service_role;

--
-- Name: FUNCTION postgis_transform_geometry(geom public.geometry, text, text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO postgres;
GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO anon;
GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO service_role;

--
-- Name: FUNCTION postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO postgres;
GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO anon;
GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO service_role;

--
-- Name: FUNCTION postgis_typmod_dims(integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO postgres;
GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO anon;
GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO service_role;

--
-- Name: FUNCTION postgis_typmod_srid(integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO postgres;
GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO anon;
GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO service_role;

--
-- Name: FUNCTION postgis_typmod_type(integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO postgres;
GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO anon;
GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO authenticated;
GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO service_role;

--
-- Name: FUNCTION postgis_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_version() TO service_role;

--
-- Name: FUNCTION postgis_wagyu_version(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO postgres;
GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO anon;
GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO authenticated;
GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO service_role;

--
-- Name: FUNCTION property_task_location_id(p_task_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.property_task_location_id(p_task_id uuid) TO anon;
GRANT ALL ON FUNCTION public.property_task_location_id(p_task_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.property_task_location_id(p_task_id uuid) TO service_role;

--
-- Name: FUNCTION property_task_user_has_access(p_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.property_task_user_has_access(p_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.property_task_user_has_access(p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.property_task_user_has_access(p_location_id uuid) TO service_role;

--
-- Name: FUNCTION st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_3ddistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_3dintersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_3dlength(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO service_role;

--
-- Name: FUNCTION st_3dlineinterpolatepoint(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_3dlongestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_3dmakebox(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_3dperimeter(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO service_role;

--
-- Name: FUNCTION st_3dshortestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_addmeasure(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_addpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_addpoint(geom1 public.geometry, geom2 public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_angle(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO service_role;

--
-- Name: FUNCTION st_area(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_area(text) TO postgres;
GRANT ALL ON FUNCTION public.st_area(text) TO anon;
GRANT ALL ON FUNCTION public.st_area(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_area(text) TO service_role;

--
-- Name: FUNCTION st_area(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_area(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_area(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_area(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_area(public.geometry) TO service_role;

--
-- Name: FUNCTION st_area(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO anon;
GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO service_role;

--
-- Name: FUNCTION st_area2d(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO service_role;

--
-- Name: FUNCTION st_asbinary(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO service_role;

--
-- Name: FUNCTION st_asbinary(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO service_role;

--
-- Name: FUNCTION st_asbinary(public.geography, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO postgres;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO anon;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO service_role;

--
-- Name: FUNCTION st_asbinary(public.geometry, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO postgres;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO anon;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO service_role;

--
-- Name: FUNCTION st_asencodedpolyline(geom public.geometry, nprecision integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO postgres;
GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO anon;
GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO service_role;

--
-- Name: FUNCTION st_asewkb(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO service_role;

--
-- Name: FUNCTION st_asewkb(public.geometry, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO postgres;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO anon;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO service_role;

--
-- Name: FUNCTION st_asewkt(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asewkt(text) TO postgres;
GRANT ALL ON FUNCTION public.st_asewkt(text) TO anon;
GRANT ALL ON FUNCTION public.st_asewkt(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asewkt(text) TO service_role;

--
-- Name: FUNCTION st_asewkt(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO service_role;

--
-- Name: FUNCTION st_asewkt(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO service_role;

--
-- Name: FUNCTION st_asewkt(public.geography, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO anon;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO service_role;

--
-- Name: FUNCTION st_asewkt(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_asgeojson(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgeojson(text) TO postgres;
GRANT ALL ON FUNCTION public.st_asgeojson(text) TO anon;
GRANT ALL ON FUNCTION public.st_asgeojson(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgeojson(text) TO service_role;

--
-- Name: FUNCTION st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO postgres;
GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO anon;
GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO service_role;

--
-- Name: FUNCTION st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO postgres;
GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO anon;
GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO service_role;

--
-- Name: FUNCTION st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO anon;
GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO service_role;

--
-- Name: FUNCTION st_asgml(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgml(text) TO postgres;
GRANT ALL ON FUNCTION public.st_asgml(text) TO anon;
GRANT ALL ON FUNCTION public.st_asgml(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgml(text) TO service_role;

--
-- Name: FUNCTION st_asgml(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO postgres;
GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO anon;
GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO service_role;

--
-- Name: FUNCTION st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO postgres;
GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO anon;
GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO service_role;

--
-- Name: FUNCTION st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO postgres;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO anon;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO service_role;

--
-- Name: FUNCTION st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO postgres;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO anon;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO service_role;

--
-- Name: FUNCTION st_ashexewkb(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO service_role;

--
-- Name: FUNCTION st_ashexewkb(public.geometry, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO postgres;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO anon;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO service_role;

--
-- Name: FUNCTION st_askml(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_askml(text) TO postgres;
GRANT ALL ON FUNCTION public.st_askml(text) TO anon;
GRANT ALL ON FUNCTION public.st_askml(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_askml(text) TO service_role;

--
-- Name: FUNCTION st_askml(geog public.geography, maxdecimaldigits integer, nprefix text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO postgres;
GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO anon;
GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO authenticated;
GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO service_role;

--
-- Name: FUNCTION st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO postgres;
GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO anon;
GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO authenticated;
GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO service_role;

--
-- Name: FUNCTION st_aslatlontext(geom public.geometry, tmpl text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO postgres;
GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO anon;
GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO authenticated;
GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO service_role;

--
-- Name: FUNCTION st_asmarc21(geom public.geometry, format text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO postgres;
GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO anon;
GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO service_role;

--
-- Name: FUNCTION st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO anon;
GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO service_role;

--
-- Name: FUNCTION st_assvg(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_assvg(text) TO postgres;
GRANT ALL ON FUNCTION public.st_assvg(text) TO anon;
GRANT ALL ON FUNCTION public.st_assvg(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_assvg(text) TO service_role;

--
-- Name: FUNCTION st_assvg(geog public.geography, rel integer, maxdecimaldigits integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO postgres;
GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO anon;
GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO service_role;

--
-- Name: FUNCTION st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO postgres;
GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO anon;
GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO service_role;

--
-- Name: FUNCTION st_astext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_astext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_astext(text) TO anon;
GRANT ALL ON FUNCTION public.st_astext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_astext(text) TO service_role;

--
-- Name: FUNCTION st_astext(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_astext(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_astext(public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_astext(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_astext(public.geography) TO service_role;

--
-- Name: FUNCTION st_astext(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO service_role;

--
-- Name: FUNCTION st_astext(public.geography, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO anon;
GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO service_role;

--
-- Name: FUNCTION st_astext(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO anon;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO service_role;

--
-- Name: FUNCTION st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO anon;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO service_role;

--
-- Name: FUNCTION st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO postgres;
GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO anon;
GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO service_role;

--
-- Name: FUNCTION st_azimuth(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO service_role;

--
-- Name: FUNCTION st_azimuth(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_bdmpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_bdpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_boundary(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO service_role;

--
-- Name: FUNCTION st_boundingdiagonal(geom public.geometry, fits boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO anon;
GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO service_role;

--
-- Name: FUNCTION st_box2dfromgeohash(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO service_role;

--
-- Name: FUNCTION st_buffer(text, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO service_role;

--
-- Name: FUNCTION st_buffer(public.geography, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO service_role;

--
-- Name: FUNCTION st_buffer(text, double precision, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO anon;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO service_role;

--
-- Name: FUNCTION st_buffer(text, double precision, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO postgres;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO anon;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO service_role;

--
-- Name: FUNCTION st_buffer(public.geography, double precision, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO anon;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO service_role;

--
-- Name: FUNCTION st_buffer(public.geography, double precision, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO postgres;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO anon;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO service_role;

--
-- Name: FUNCTION st_buffer(geom public.geometry, radius double precision, quadsegs integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO postgres;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO anon;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO service_role;

--
-- Name: FUNCTION st_buffer(geom public.geometry, radius double precision, options text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO postgres;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO anon;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO authenticated;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO service_role;

--
-- Name: FUNCTION st_buildarea(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO service_role;

--
-- Name: FUNCTION st_centroid(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_centroid(text) TO postgres;
GRANT ALL ON FUNCTION public.st_centroid(text) TO anon;
GRANT ALL ON FUNCTION public.st_centroid(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_centroid(text) TO service_role;

--
-- Name: FUNCTION st_centroid(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO service_role;

--
-- Name: FUNCTION st_centroid(public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO anon;
GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO service_role;

--
-- Name: FUNCTION st_chaikinsmoothing(public.geometry, integer, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO anon;
GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO service_role;

--
-- Name: FUNCTION st_cleangeometry(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO service_role;

--
-- Name: FUNCTION st_clipbybox2d(geom public.geometry, box public.box2d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO postgres;
GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO anon;
GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO authenticated;
GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO service_role;

--
-- Name: FUNCTION st_closestpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_closestpointofapproach(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION st_clusterdbscan(public.geometry, eps double precision, minpoints integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO postgres;
GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO anon;
GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO service_role;

--
-- Name: FUNCTION st_clusterintersecting(public.geometry[]); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO postgres;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO anon;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO authenticated;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO service_role;

--
-- Name: FUNCTION st_clusterkmeans(geom public.geometry, k integer, max_radius double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO anon;
GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO service_role;

--
-- Name: FUNCTION st_clusterwithin(public.geometry[], double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO anon;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO service_role;

--
-- Name: FUNCTION st_collect(public.geometry[]); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO postgres;
GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO anon;
GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO authenticated;
GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO service_role;

--
-- Name: FUNCTION st_collect(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_collectionextract(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO service_role;

--
-- Name: FUNCTION st_collectionextract(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_collectionhomogenize(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO service_role;

--
-- Name: FUNCTION st_combinebbox(public.box2d, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO service_role;

--
-- Name: FUNCTION st_combinebbox(public.box3d, public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO anon;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO service_role;

--
-- Name: FUNCTION st_combinebbox(public.box3d, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO service_role;

--
-- Name: FUNCTION st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO anon;
GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO service_role;

--
-- Name: FUNCTION st_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_containsproperly(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_convexhull(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO service_role;

--
-- Name: FUNCTION st_coorddim(geometry public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO service_role;

--
-- Name: FUNCTION st_coveredby(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO anon;
GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO service_role;

--
-- Name: FUNCTION st_coveredby(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO service_role;

--
-- Name: FUNCTION st_coveredby(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_covers(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_covers(text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_covers(text, text) TO anon;
GRANT ALL ON FUNCTION public.st_covers(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_covers(text, text) TO service_role;

--
-- Name: FUNCTION st_covers(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO service_role;

--
-- Name: FUNCTION st_covers(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_cpawithin(public.geometry, public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_crosses(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO postgres;
GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO anon;
GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO service_role;

--
-- Name: FUNCTION st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO postgres;
GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO anon;
GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO service_role;

--
-- Name: FUNCTION st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO anon;
GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO service_role;

--
-- Name: FUNCTION st_dimension(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO service_role;

--
-- Name: FUNCTION st_disjoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_distance(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_distance(text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_distance(text, text) TO anon;
GRANT ALL ON FUNCTION public.st_distance(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_distance(text, text) TO service_role;

--
-- Name: FUNCTION st_distance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO anon;
GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO service_role;

--
-- Name: FUNCTION st_distancecpa(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION st_distancesphere(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO anon;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO service_role;

--
-- Name: FUNCTION st_distancespheroid(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO postgres;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO anon;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO authenticated;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO service_role;

--
-- Name: FUNCTION st_dump(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO service_role;

--
-- Name: FUNCTION st_dumppoints(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO service_role;

--
-- Name: FUNCTION st_dumprings(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO service_role;

--
-- Name: FUNCTION st_dumpsegments(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO service_role;

--
-- Name: FUNCTION st_dwithin(text, text, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO service_role;

--
-- Name: FUNCTION st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO anon;
GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO service_role;

--
-- Name: FUNCTION st_endpoint(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO service_role;

--
-- Name: FUNCTION st_envelope(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO service_role;

--
-- Name: FUNCTION st_equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_estimatedextent(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO anon;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO service_role;

--
-- Name: FUNCTION st_estimatedextent(text, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO anon;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO service_role;

--
-- Name: FUNCTION st_estimatedextent(text, text, text, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO anon;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO service_role;

--
-- Name: FUNCTION st_expand(public.box2d, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO service_role;

--
-- Name: FUNCTION st_expand(public.box3d, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO service_role;

--
-- Name: FUNCTION st_expand(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_expand(box public.box2d, dx double precision, dy double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO anon;
GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO service_role;

--
-- Name: FUNCTION st_expand(box public.box3d, dx double precision, dy double precision, dz double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO anon;
GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO service_role;

--
-- Name: FUNCTION st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO anon;
GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO service_role;

--
-- Name: FUNCTION st_exteriorring(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO service_role;

--
-- Name: FUNCTION st_filterbym(public.geometry, double precision, double precision, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO anon;
GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO service_role;

--
-- Name: FUNCTION st_findextent(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_findextent(text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_findextent(text, text) TO anon;
GRANT ALL ON FUNCTION public.st_findextent(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_findextent(text, text) TO service_role;

--
-- Name: FUNCTION st_findextent(text, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO anon;
GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO service_role;

--
-- Name: FUNCTION st_flipcoordinates(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO service_role;

--
-- Name: FUNCTION st_force2d(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO service_role;

--
-- Name: FUNCTION st_force3d(geom public.geometry, zvalue double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO anon;
GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO service_role;

--
-- Name: FUNCTION st_force3dm(geom public.geometry, mvalue double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO anon;
GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO service_role;

--
-- Name: FUNCTION st_force3dz(geom public.geometry, zvalue double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO anon;
GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO service_role;

--
-- Name: FUNCTION st_force4d(geom public.geometry, zvalue double precision, mvalue double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO anon;
GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO service_role;

--
-- Name: FUNCTION st_forcecollection(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO service_role;

--
-- Name: FUNCTION st_forcecurve(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO service_role;

--
-- Name: FUNCTION st_forcepolygonccw(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO service_role;

--
-- Name: FUNCTION st_forcepolygoncw(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO service_role;

--
-- Name: FUNCTION st_forcerhr(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO service_role;

--
-- Name: FUNCTION st_forcesfs(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO service_role;

--
-- Name: FUNCTION st_forcesfs(public.geometry, version text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO postgres;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO anon;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO authenticated;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO service_role;

--
-- Name: FUNCTION st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_fromflatgeobuf(anyelement, bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO anon;
GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO service_role;

--
-- Name: FUNCTION st_fromflatgeobuftotable(text, text, bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO anon;
GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO service_role;

--
-- Name: FUNCTION st_generatepoints(area public.geometry, npoints integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO postgres;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO anon;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO service_role;

--
-- Name: FUNCTION st_generatepoints(area public.geometry, npoints integer, seed integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO postgres;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO anon;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO service_role;

--
-- Name: FUNCTION st_geogfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO service_role;

--
-- Name: FUNCTION st_geogfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_geographyfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO service_role;

--
-- Name: FUNCTION st_geohash(geog public.geography, maxchars integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO anon;
GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO service_role;

--
-- Name: FUNCTION st_geohash(geom public.geometry, maxchars integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO anon;
GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO service_role;

--
-- Name: FUNCTION st_geomcollfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO service_role;

--
-- Name: FUNCTION st_geomcollfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_geomcollfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_geomcollfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO anon;
GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO service_role;

--
-- Name: FUNCTION st_geometryfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO service_role;

--
-- Name: FUNCTION st_geometryfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_geometryn(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_geometrytype(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO service_role;

--
-- Name: FUNCTION st_geomfromewkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO service_role;

--
-- Name: FUNCTION st_geomfromewkt(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO service_role;

--
-- Name: FUNCTION st_geomfromgeohash(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO service_role;

--
-- Name: FUNCTION st_geomfromgeojson(json); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO service_role;

--
-- Name: FUNCTION st_geomfromgeojson(jsonb); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO service_role;

--
-- Name: FUNCTION st_geomfromgeojson(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO service_role;

--
-- Name: FUNCTION st_geomfromgml(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO service_role;

--
-- Name: FUNCTION st_geomfromgml(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO service_role;

--
-- Name: FUNCTION st_geomfromkml(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO service_role;

--
-- Name: FUNCTION st_geomfrommarc21(marc21xml text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO anon;
GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO service_role;

--
-- Name: FUNCTION st_geomfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO service_role;

--
-- Name: FUNCTION st_geomfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_geomfromtwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_geomfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_geomfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_gmltosql(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_gmltosql(text) TO postgres;
GRANT ALL ON FUNCTION public.st_gmltosql(text) TO anon;
GRANT ALL ON FUNCTION public.st_gmltosql(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_gmltosql(text) TO service_role;

--
-- Name: FUNCTION st_gmltosql(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO service_role;

--
-- Name: FUNCTION st_hasarc(geometry public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO service_role;

--
-- Name: FUNCTION st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO service_role;

--
-- Name: FUNCTION st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO postgres;
GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO anon;
GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO service_role;

--
-- Name: FUNCTION st_interiorringn(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_interpolatepoint(line public.geometry, point public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO service_role;

--
-- Name: FUNCTION st_intersection(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_intersection(text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_intersection(text, text) TO anon;
GRANT ALL ON FUNCTION public.st_intersection(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_intersection(text, text) TO service_role;

--
-- Name: FUNCTION st_intersection(public.geography, public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO service_role;

--
-- Name: FUNCTION st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO anon;
GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO service_role;

--
-- Name: FUNCTION st_intersects(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_intersects(text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_intersects(text, text) TO anon;
GRANT ALL ON FUNCTION public.st_intersects(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_intersects(text, text) TO service_role;

--
-- Name: FUNCTION st_intersects(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO service_role;

--
-- Name: FUNCTION st_intersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_isclosed(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO service_role;

--
-- Name: FUNCTION st_iscollection(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO service_role;

--
-- Name: FUNCTION st_isempty(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO service_role;

--
-- Name: FUNCTION st_ispolygonccw(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO service_role;

--
-- Name: FUNCTION st_ispolygoncw(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO service_role;

--
-- Name: FUNCTION st_isring(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO service_role;

--
-- Name: FUNCTION st_issimple(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO service_role;

--
-- Name: FUNCTION st_isvalid(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO service_role;

--
-- Name: FUNCTION st_isvalid(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_isvaliddetail(geom public.geometry, flags integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO postgres;
GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO anon;
GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO service_role;

--
-- Name: FUNCTION st_isvalidreason(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO service_role;

--
-- Name: FUNCTION st_isvalidreason(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_isvalidtrajectory(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO service_role;

--
-- Name: FUNCTION st_length(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_length(text) TO postgres;
GRANT ALL ON FUNCTION public.st_length(text) TO anon;
GRANT ALL ON FUNCTION public.st_length(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_length(text) TO service_role;

--
-- Name: FUNCTION st_length(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_length(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_length(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_length(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_length(public.geometry) TO service_role;

--
-- Name: FUNCTION st_length(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO anon;
GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO service_role;

--
-- Name: FUNCTION st_length2d(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO service_role;

--
-- Name: FUNCTION st_length2dspheroid(public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO postgres;
GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO anon;
GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO authenticated;
GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO service_role;

--
-- Name: FUNCTION st_lengthspheroid(public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO postgres;
GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO anon;
GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO authenticated;
GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO service_role;

--
-- Name: FUNCTION st_letters(letters text, font json); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO postgres;
GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO anon;
GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO authenticated;
GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO service_role;

--
-- Name: FUNCTION st_linecrossingdirection(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_linefromencodedpolyline(txtin text, nprecision integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO postgres;
GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO anon;
GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO service_role;

--
-- Name: FUNCTION st_linefrommultipoint(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO service_role;

--
-- Name: FUNCTION st_linefromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linefromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_linefromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_linefromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_linefromtext(text) TO service_role;

--
-- Name: FUNCTION st_linefromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_linefromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_linefromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_lineinterpolatepoint(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_lineinterpolatepoints(public.geometry, double precision, repeat boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO anon;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO service_role;

--
-- Name: FUNCTION st_linelocatepoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_linemerge(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO service_role;

--
-- Name: FUNCTION st_linemerge(public.geometry, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO anon;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO service_role;

--
-- Name: FUNCTION st_linestringfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_linestringfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_linesubstring(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_linetocurve(geometry public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO service_role;

--
-- Name: FUNCTION st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO anon;
GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO service_role;

--
-- Name: FUNCTION st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO anon;
GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO service_role;

--
-- Name: FUNCTION st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO anon;
GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO service_role;

--
-- Name: FUNCTION st_longestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_m(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_m(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_m(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_m(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_m(public.geometry) TO service_role;

--
-- Name: FUNCTION st_makebox2d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_makeenvelope(double precision, double precision, double precision, double precision, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO anon;
GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO service_role;

--
-- Name: FUNCTION st_makeline(public.geometry[]); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO postgres;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO anon;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO authenticated;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO service_role;

--
-- Name: FUNCTION st_makeline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_makepoint(double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_makepointm(double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_makepolygon(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO service_role;

--
-- Name: FUNCTION st_makepolygon(public.geometry, public.geometry[]); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO postgres;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO anon;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO authenticated;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO service_role;

--
-- Name: FUNCTION st_makevalid(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO service_role;

--
-- Name: FUNCTION st_makevalid(geom public.geometry, params text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO postgres;
GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO anon;
GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO authenticated;
GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO service_role;

--
-- Name: FUNCTION st_maxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO anon;
GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO service_role;

--
-- Name: FUNCTION st_memsize(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO service_role;

--
-- Name: FUNCTION st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO postgres;
GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO anon;
GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO service_role;

--
-- Name: FUNCTION st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO anon;
GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO service_role;

--
-- Name: FUNCTION st_minimumclearance(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO service_role;

--
-- Name: FUNCTION st_minimumclearanceline(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO service_role;

--
-- Name: FUNCTION st_mlinefromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO service_role;

--
-- Name: FUNCTION st_mlinefromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_mlinefromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_mlinefromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_mpointfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO service_role;

--
-- Name: FUNCTION st_mpointfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_mpointfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_mpointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_mpolyfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO service_role;

--
-- Name: FUNCTION st_mpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_mpolyfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_mpolyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_multi(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO service_role;

--
-- Name: FUNCTION st_multilinefromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_multilinestringfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO service_role;

--
-- Name: FUNCTION st_multilinestringfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_multipointfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO service_role;

--
-- Name: FUNCTION st_multipointfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_multipointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_multipolyfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_multipolyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_multipolygonfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO service_role;

--
-- Name: FUNCTION st_multipolygonfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_ndims(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO service_role;

--
-- Name: FUNCTION st_node(g public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO service_role;

--
-- Name: FUNCTION st_normalize(geom public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO service_role;

--
-- Name: FUNCTION st_npoints(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO service_role;

--
-- Name: FUNCTION st_nrings(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO service_role;

--
-- Name: FUNCTION st_numgeometries(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO service_role;

--
-- Name: FUNCTION st_numinteriorring(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO service_role;

--
-- Name: FUNCTION st_numinteriorrings(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO service_role;

--
-- Name: FUNCTION st_numpatches(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO service_role;

--
-- Name: FUNCTION st_numpoints(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO service_role;

--
-- Name: FUNCTION st_offsetcurve(line public.geometry, distance double precision, params text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO postgres;
GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO anon;
GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO authenticated;
GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO service_role;

--
-- Name: FUNCTION st_orderingequals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_orientedenvelope(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO service_role;

--
-- Name: FUNCTION st_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_patchn(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_perimeter(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO service_role;

--
-- Name: FUNCTION st_perimeter(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO anon;
GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO service_role;

--
-- Name: FUNCTION st_perimeter2d(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO service_role;

--
-- Name: FUNCTION st_point(double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_point(double precision, double precision, srid integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO postgres;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO anon;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO service_role;

--
-- Name: FUNCTION st_pointfromgeohash(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO service_role;

--
-- Name: FUNCTION st_pointfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO service_role;

--
-- Name: FUNCTION st_pointfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_pointfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_pointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_pointinsidecircle(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO postgres;
GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO anon;
GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO service_role;

--
-- Name: FUNCTION st_pointn(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_pointonsurface(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO service_role;

--
-- Name: FUNCTION st_points(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_points(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_points(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_points(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_points(public.geometry) TO service_role;

--
-- Name: FUNCTION st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO postgres;
GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO anon;
GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO service_role;

--
-- Name: FUNCTION st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO postgres;
GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO anon;
GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO service_role;

--
-- Name: FUNCTION st_polyfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO service_role;

--
-- Name: FUNCTION st_polyfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_polyfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_polyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_polygon(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_polygonfromtext(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO postgres;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO anon;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO service_role;

--
-- Name: FUNCTION st_polygonfromtext(text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO service_role;

--
-- Name: FUNCTION st_polygonfromwkb(bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO anon;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO service_role;

--
-- Name: FUNCTION st_polygonfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO anon;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO service_role;

--
-- Name: FUNCTION st_polygonize(public.geometry[]); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO postgres;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO anon;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO authenticated;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO service_role;

--
-- Name: FUNCTION st_project(geog public.geography, distance double precision, azimuth double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO anon;
GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO service_role;

--
-- Name: FUNCTION st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO postgres;
GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO anon;
GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO service_role;

--
-- Name: FUNCTION st_reduceprecision(geom public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO anon;
GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO service_role;

--
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO postgres;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO anon;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO service_role;

--
-- Name: FUNCTION st_relatematch(text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO anon;
GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO service_role;

--
-- Name: FUNCTION st_removepoint(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_removerepeatedpoints(geom public.geometry, tolerance double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO anon;
GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO service_role;

--
-- Name: FUNCTION st_reverse(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO service_role;

--
-- Name: FUNCTION st_rotate(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_rotate(public.geometry, double precision, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO service_role;

--
-- Name: FUNCTION st_rotate(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_rotatex(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_rotatey(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_rotatez(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_scale(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION st_scale(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_scale(public.geometry, public.geometry, origin public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO service_role;

--
-- Name: FUNCTION st_scale(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_scroll(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO service_role;

--
-- Name: FUNCTION st_segmentize(geog public.geography, max_segment_length double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO anon;
GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO service_role;

--
-- Name: FUNCTION st_segmentize(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_seteffectivearea(public.geometry, double precision, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO anon;
GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO service_role;

--
-- Name: FUNCTION st_setpoint(public.geometry, integer, public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO service_role;

--
-- Name: FUNCTION st_setsrid(geog public.geography, srid integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO postgres;
GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO anon;
GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO service_role;

--
-- Name: FUNCTION st_setsrid(geom public.geometry, srid integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO postgres;
GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO anon;
GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO service_role;

--
-- Name: FUNCTION st_sharedpaths(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_shiftlongitude(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO service_role;

--
-- Name: FUNCTION st_shortestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_simplify(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_simplify(public.geometry, double precision, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO anon;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO service_role;

--
-- Name: FUNCTION st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO anon;
GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO service_role;

--
-- Name: FUNCTION st_simplifypreservetopology(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_simplifyvw(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_snap(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_split(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO service_role;

--
-- Name: FUNCTION st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO postgres;
GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO anon;
GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO service_role;

--
-- Name: FUNCTION st_srid(geog public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO service_role;

--
-- Name: FUNCTION st_srid(geom public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO service_role;

--
-- Name: FUNCTION st_startpoint(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO service_role;

--
-- Name: FUNCTION st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO anon;
GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO service_role;

--
-- Name: FUNCTION st_summary(public.geography); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_summary(public.geography) TO postgres;
GRANT ALL ON FUNCTION public.st_summary(public.geography) TO anon;
GRANT ALL ON FUNCTION public.st_summary(public.geography) TO authenticated;
GRANT ALL ON FUNCTION public.st_summary(public.geography) TO service_role;

--
-- Name: FUNCTION st_summary(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO service_role;

--
-- Name: FUNCTION st_swapordinates(geom public.geometry, ords cstring); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO postgres;
GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO anon;
GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO authenticated;
GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO service_role;

--
-- Name: FUNCTION st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO anon;
GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO service_role;

--
-- Name: FUNCTION st_symmetricdifference(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO anon;
GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO service_role;

--
-- Name: FUNCTION st_touches(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_transform(public.geometry, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO anon;
GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO service_role;

--
-- Name: FUNCTION st_transform(geom public.geometry, to_proj text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO postgres;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO anon;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO authenticated;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO service_role;

--
-- Name: FUNCTION st_transform(geom public.geometry, from_proj text, to_srid integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO postgres;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO anon;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO service_role;

--
-- Name: FUNCTION st_transform(geom public.geometry, from_proj text, to_proj text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO postgres;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO anon;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO authenticated;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO service_role;

--
-- Name: FUNCTION st_translate(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_translate(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_transscale(public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO service_role;

--
-- Name: FUNCTION st_triangulatepolygon(g1 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO service_role;

--
-- Name: FUNCTION st_unaryunion(public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO anon;
GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO service_role;

--
-- Name: FUNCTION st_union(public.geometry[]); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO postgres;
GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO anon;
GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO authenticated;
GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO service_role;

--
-- Name: FUNCTION st_union(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO anon;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO service_role;

--
-- Name: FUNCTION st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO service_role;

--
-- Name: FUNCTION st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO service_role;

--
-- Name: FUNCTION st_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO service_role;

--
-- Name: FUNCTION st_wkbtosql(wkb bytea); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO postgres;
GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO anon;
GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO authenticated;
GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO service_role;

--
-- Name: FUNCTION st_wkttosql(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_wkttosql(text) TO postgres;
GRANT ALL ON FUNCTION public.st_wkttosql(text) TO anon;
GRANT ALL ON FUNCTION public.st_wkttosql(text) TO authenticated;
GRANT ALL ON FUNCTION public.st_wkttosql(text) TO service_role;

--
-- Name: FUNCTION st_wrapx(geom public.geometry, wrap double precision, move double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO anon;
GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO service_role;

--
-- Name: FUNCTION st_x(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_x(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_x(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_x(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_x(public.geometry) TO service_role;

--
-- Name: FUNCTION st_xmax(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO service_role;

--
-- Name: FUNCTION st_xmin(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO service_role;

--
-- Name: FUNCTION st_y(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_y(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_y(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_y(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_y(public.geometry) TO service_role;

--
-- Name: FUNCTION st_ymax(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO service_role;

--
-- Name: FUNCTION st_ymin(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO service_role;

--
-- Name: FUNCTION st_z(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_z(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_z(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_z(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_z(public.geometry) TO service_role;

--
-- Name: FUNCTION st_zmax(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO service_role;

--
-- Name: FUNCTION st_zmflag(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO service_role;

--
-- Name: FUNCTION st_zmin(public.box3d); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO postgres;
GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO anon;
GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO authenticated;
GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO service_role;

--
-- Name: FUNCTION start_task_with_validation(p_task_id uuid, p_user_lat double precision, p_user_lon double precision, p_scanned_qr text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.start_task_with_validation(p_task_id uuid, p_user_lat double precision, p_user_lon double precision, p_scanned_qr text) TO anon;
GRANT ALL ON FUNCTION public.start_task_with_validation(p_task_id uuid, p_user_lat double precision, p_user_lon double precision, p_scanned_qr text) TO authenticated;
GRANT ALL ON FUNCTION public.start_task_with_validation(p_task_id uuid, p_user_lat double precision, p_user_lon double precision, p_scanned_qr text) TO service_role;

--
-- Name: FUNCTION unlockrows(text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.unlockrows(text) TO postgres;
GRANT ALL ON FUNCTION public.unlockrows(text) TO anon;
GRANT ALL ON FUNCTION public.unlockrows(text) TO authenticated;
GRANT ALL ON FUNCTION public.unlockrows(text) TO service_role;

--
-- Name: FUNCTION update_location_holidays_updated_at(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_location_holidays_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_location_holidays_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_location_holidays_updated_at() TO service_role;

--
-- Name: FUNCTION updategeometrysrid(character varying, character varying, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO postgres;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO anon;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO authenticated;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO service_role;

--
-- Name: FUNCTION updategeometrysrid(character varying, character varying, character varying, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO postgres;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO anon;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO authenticated;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO service_role;

--
-- Name: FUNCTION updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO postgres;
GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO anon;
GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO authenticated;
GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO service_role;

--
-- Name: TABLE companies; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.companies TO anon;
GRANT ALL ON TABLE public.companies TO authenticated;
GRANT ALL ON TABLE public.companies TO service_role;

--
-- Name: FUNCTION upsert_company_by_tax_id(p_org_id uuid, p_name text, p_tax_id text, p_category public.company_category, p_email text, p_phone text, p_address text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.upsert_company_by_tax_id(p_org_id uuid, p_name text, p_tax_id text, p_category public.company_category, p_email text, p_phone text, p_address text) TO anon;
GRANT ALL ON FUNCTION public.upsert_company_by_tax_id(p_org_id uuid, p_name text, p_tax_id text, p_category public.company_category, p_email text, p_phone text, p_address text) TO authenticated;
GRANT ALL ON FUNCTION public.upsert_company_by_tax_id(p_org_id uuid, p_name text, p_tax_id text, p_category public.company_category, p_email text, p_phone text, p_address text) TO service_role;

--
-- Name: FUNCTION user_has_location_access_docs(p_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.user_has_location_access_docs(p_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.user_has_location_access_docs(p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.user_has_location_access_docs(p_location_id uuid) TO service_role;

--
-- Name: FUNCTION st_3dextent(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO service_role;

--
-- Name: FUNCTION st_asflatgeobuf(anyelement); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO postgres;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO anon;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO authenticated;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO service_role;

--
-- Name: FUNCTION st_asflatgeobuf(anyelement, boolean); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO postgres;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO anon;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO authenticated;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO service_role;

--
-- Name: FUNCTION st_asflatgeobuf(anyelement, boolean, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO postgres;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO anon;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO service_role;

--
-- Name: FUNCTION st_asgeobuf(anyelement); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO postgres;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO anon;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO service_role;

--
-- Name: FUNCTION st_asgeobuf(anyelement, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO postgres;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO anon;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO service_role;

--
-- Name: FUNCTION st_asmvt(anyelement); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO postgres;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO anon;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO authenticated;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO service_role;

--
-- Name: FUNCTION st_asmvt(anyelement, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO postgres;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO anon;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO service_role;

--
-- Name: FUNCTION st_asmvt(anyelement, text, integer); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO postgres;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO anon;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO authenticated;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO service_role;

--
-- Name: FUNCTION st_asmvt(anyelement, text, integer, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO postgres;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO anon;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO service_role;

--
-- Name: FUNCTION st_asmvt(anyelement, text, integer, text, text); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO postgres;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO anon;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO authenticated;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO service_role;

--
-- Name: FUNCTION st_clusterintersecting(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO service_role;

--
-- Name: FUNCTION st_clusterwithin(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO service_role;

--
-- Name: FUNCTION st_collect(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO service_role;

--
-- Name: FUNCTION st_extent(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO service_role;

--
-- Name: FUNCTION st_makeline(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO service_role;

--
-- Name: FUNCTION st_memcollect(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO service_role;

--
-- Name: FUNCTION st_memunion(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO service_role;

--
-- Name: FUNCTION st_polygonize(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO service_role;

--
-- Name: FUNCTION st_union(public.geometry); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_union(public.geometry) TO postgres;
GRANT ALL ON FUNCTION public.st_union(public.geometry) TO anon;
GRANT ALL ON FUNCTION public.st_union(public.geometry) TO authenticated;
GRANT ALL ON FUNCTION public.st_union(public.geometry) TO service_role;

--
-- Name: FUNCTION st_union(public.geometry, double precision); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO postgres;
GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO anon;
GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO authenticated;
GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO service_role;

--
-- Name: TABLE admin_contracts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.admin_contracts TO anon;
GRANT ALL ON TABLE public.admin_contracts TO authenticated;
GRANT ALL ON TABLE public.admin_contracts TO service_role;

--
-- Name: TABLE applications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.applications TO anon;
GRANT ALL ON TABLE public.applications TO authenticated;
GRANT ALL ON TABLE public.applications TO service_role;

--
-- Name: TABLE task_execution_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.task_execution_logs TO anon;
GRANT ALL ON TABLE public.task_execution_logs TO authenticated;
GRANT ALL ON TABLE public.task_execution_logs TO service_role;

--
-- Name: TABLE cleaner_recent_activity; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cleaner_recent_activity TO anon;
GRANT ALL ON TABLE public.cleaner_recent_activity TO authenticated;
GRANT ALL ON TABLE public.cleaner_recent_activity TO service_role;

--
-- Name: TABLE cleaning_catalog; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cleaning_catalog TO anon;
GRANT ALL ON TABLE public.cleaning_catalog TO authenticated;
GRANT ALL ON TABLE public.cleaning_catalog TO service_role;

--
-- Name: TABLE cleaning_clients; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cleaning_clients TO anon;
GRANT ALL ON TABLE public.cleaning_clients TO authenticated;
GRANT ALL ON TABLE public.cleaning_clients TO service_role;

--
-- Name: TABLE cleaning_inventory; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cleaning_inventory TO anon;
GRANT ALL ON TABLE public.cleaning_inventory TO authenticated;
GRANT ALL ON TABLE public.cleaning_inventory TO service_role;

--
-- Name: TABLE cleaning_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cleaning_locations TO anon;
GRANT ALL ON TABLE public.cleaning_locations TO authenticated;
GRANT ALL ON TABLE public.cleaning_locations TO service_role;

--
-- Name: TABLE cleaning_staff; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cleaning_staff TO anon;
GRANT ALL ON TABLE public.cleaning_staff TO authenticated;
GRANT ALL ON TABLE public.cleaning_staff TO service_role;

--
-- Name: TABLE cleaning_tasks; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cleaning_tasks TO anon;
GRANT ALL ON TABLE public.cleaning_tasks TO authenticated;
GRANT ALL ON TABLE public.cleaning_tasks TO service_role;

--
-- Name: TABLE communities; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.communities TO anon;
GRANT ALL ON TABLE public.communities TO authenticated;
GRANT ALL ON TABLE public.communities TO service_role;

--
-- Name: TABLE community_board; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.community_board TO anon;
GRANT ALL ON TABLE public.community_board TO authenticated;
GRANT ALL ON TABLE public.community_board TO service_role;

--
-- Name: TABLE community_comments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.community_comments TO anon;
GRANT ALL ON TABLE public.community_comments TO authenticated;
GRANT ALL ON TABLE public.community_comments TO service_role;

--
-- Name: TABLE e_board_messages; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.e_board_messages TO anon;
GRANT ALL ON TABLE public.e_board_messages TO authenticated;
GRANT ALL ON TABLE public.e_board_messages TO service_role;

--
-- Name: TABLE fuel_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.fuel_logs TO anon;
GRANT ALL ON TABLE public.fuel_logs TO authenticated;
GRANT ALL ON TABLE public.fuel_logs TO service_role;

--
-- Name: TABLE inspection_campaigns; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.inspection_campaigns TO anon;
GRANT ALL ON TABLE public.inspection_campaigns TO authenticated;
GRANT ALL ON TABLE public.inspection_campaigns TO service_role;

--
-- Name: TABLE inspections; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.inspections TO anon;
GRANT ALL ON TABLE public.inspections TO authenticated;
GRANT ALL ON TABLE public.inspections TO service_role;

--
-- Name: TABLE inspections_hybrid; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.inspections_hybrid TO anon;
GRANT ALL ON TABLE public.inspections_hybrid TO authenticated;
GRANT ALL ON TABLE public.inspections_hybrid TO service_role;

--
-- Name: TABLE internal_tasks; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.internal_tasks TO anon;
GRANT ALL ON TABLE public.internal_tasks TO authenticated;
GRANT ALL ON TABLE public.internal_tasks TO service_role;

--
-- Name: TABLE legal_documents; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.legal_documents TO anon;
GRANT ALL ON TABLE public.legal_documents TO authenticated;
GRANT ALL ON TABLE public.legal_documents TO service_role;

--
-- Name: TABLE location_access; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.location_access TO anon;
GRANT ALL ON TABLE public.location_access TO authenticated;
GRANT ALL ON TABLE public.location_access TO service_role;

--
-- Name: TABLE location_holidays; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.location_holidays TO anon;
GRANT ALL ON TABLE public.location_holidays TO authenticated;
GRANT ALL ON TABLE public.location_holidays TO service_role;

--
-- Name: TABLE location_vendor_routing; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.location_vendor_routing TO anon;
GRANT ALL ON TABLE public.location_vendor_routing TO authenticated;
GRANT ALL ON TABLE public.location_vendor_routing TO service_role;

--
-- Name: TABLE locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.locations TO anon;
GRANT ALL ON TABLE public.locations TO authenticated;
GRANT ALL ON TABLE public.locations TO service_role;

--
-- Name: TABLE material_requests; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.material_requests TO anon;
GRANT ALL ON TABLE public.material_requests TO authenticated;
GRANT ALL ON TABLE public.material_requests TO service_role;

--
-- Name: TABLE memberships; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.memberships TO anon;
GRANT ALL ON TABLE public.memberships TO authenticated;
GRANT ALL ON TABLE public.memberships TO service_role;

--
-- Name: TABLE notification_templates; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.notification_templates TO anon;
GRANT ALL ON TABLE public.notification_templates TO authenticated;
GRANT ALL ON TABLE public.notification_templates TO service_role;

--
-- Name: TABLE offer_interactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.offer_interactions TO anon;
GRANT ALL ON TABLE public.offer_interactions TO authenticated;
GRANT ALL ON TABLE public.offer_interactions TO service_role;

--
-- Name: TABLE org_subscriptions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.org_subscriptions TO anon;
GRANT ALL ON TABLE public.org_subscriptions TO authenticated;
GRANT ALL ON TABLE public.org_subscriptions TO service_role;

--
-- Name: TABLE organizations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.organizations TO anon;
GRANT ALL ON TABLE public.organizations TO authenticated;
GRANT ALL ON TABLE public.organizations TO service_role;

--
-- Name: TABLE page_content; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.page_content TO anon;
GRANT ALL ON TABLE public.page_content TO authenticated;
GRANT ALL ON TABLE public.page_content TO service_role;

--
-- Name: TABLE partner_offers; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.partner_offers TO anon;
GRANT ALL ON TABLE public.partner_offers TO authenticated;
GRANT ALL ON TABLE public.partner_offers TO service_role;

--
-- Name: TABLE pricing_plans; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.pricing_plans TO anon;
GRANT ALL ON TABLE public.pricing_plans TO authenticated;
GRANT ALL ON TABLE public.pricing_plans TO service_role;

--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;

--
-- Name: TABLE promo_codes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.promo_codes TO anon;
GRANT ALL ON TABLE public.promo_codes TO authenticated;
GRANT ALL ON TABLE public.promo_codes TO service_role;

--
-- Name: TABLE property_checklists; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.property_checklists TO anon;
GRANT ALL ON TABLE public.property_checklists TO authenticated;
GRANT ALL ON TABLE public.property_checklists TO service_role;

--
-- Name: TABLE property_contracts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.property_contracts TO anon;
GRANT ALL ON TABLE public.property_contracts TO authenticated;
GRANT ALL ON TABLE public.property_contracts TO service_role;

--
-- Name: TABLE property_inspections; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.property_inspections TO anon;
GRANT ALL ON TABLE public.property_inspections TO authenticated;
GRANT ALL ON TABLE public.property_inspections TO service_role;

--
-- Name: TABLE property_issues; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.property_issues TO anon;
GRANT ALL ON TABLE public.property_issues TO authenticated;
GRANT ALL ON TABLE public.property_issues TO service_role;

--
-- Name: TABLE property_policies; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.property_policies TO anon;
GRANT ALL ON TABLE public.property_policies TO authenticated;
GRANT ALL ON TABLE public.property_policies TO service_role;

--
-- Name: TABLE property_sections; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.property_sections TO anon;
GRANT ALL ON TABLE public.property_sections TO authenticated;
GRANT ALL ON TABLE public.property_sections TO service_role;

--
-- Name: TABLE property_tasks; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.property_tasks TO anon;
GRANT ALL ON TABLE public.property_tasks TO authenticated;
GRANT ALL ON TABLE public.property_tasks TO service_role;

--
-- Name: TABLE repair_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.repair_logs TO anon;
GRANT ALL ON TABLE public.repair_logs TO authenticated;
GRANT ALL ON TABLE public.repair_logs TO service_role;

--
-- Name: TABLE resident_configs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.resident_configs TO anon;
GRANT ALL ON TABLE public.resident_configs TO authenticated;
GRANT ALL ON TABLE public.resident_configs TO service_role;

--
-- Name: TABLE staff_equipment; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.staff_equipment TO anon;
GRANT ALL ON TABLE public.staff_equipment TO authenticated;
GRANT ALL ON TABLE public.staff_equipment TO service_role;

--
-- Name: TABLE staff_financial_adjustments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.staff_financial_adjustments TO anon;
GRANT ALL ON TABLE public.staff_financial_adjustments TO authenticated;
GRANT ALL ON TABLE public.staff_financial_adjustments TO service_role;

--
-- Name: TABLE staff_payouts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.staff_payouts TO anon;
GRANT ALL ON TABLE public.staff_payouts TO authenticated;
GRANT ALL ON TABLE public.staff_payouts TO service_role;

--
-- Name: TABLE staff_rate_history; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.staff_rate_history TO anon;
GRANT ALL ON TABLE public.staff_rate_history TO authenticated;
GRANT ALL ON TABLE public.staff_rate_history TO service_role;

--
-- Name: TABLE task_comments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.task_comments TO anon;
GRANT ALL ON TABLE public.task_comments TO authenticated;
GRANT ALL ON TABLE public.task_comments TO service_role;

--
-- Name: TABLE task_step_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.task_step_logs TO anon;
GRANT ALL ON TABLE public.task_step_logs TO authenticated;
GRANT ALL ON TABLE public.task_step_logs TO service_role;

--
-- Name: TABLE unit_inspection_records; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.unit_inspection_records TO anon;
GRANT ALL ON TABLE public.unit_inspection_records TO authenticated;
GRANT ALL ON TABLE public.unit_inspection_records TO service_role;

--
-- Name: TABLE user_app_access; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_app_access TO anon;
GRANT ALL ON TABLE public.user_app_access TO authenticated;
GRANT ALL ON TABLE public.user_app_access TO service_role;

--
-- Name: TABLE vehicles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.vehicles TO anon;
GRANT ALL ON TABLE public.vehicles TO authenticated;
GRANT ALL ON TABLE public.vehicles TO service_role;

--
-- Name: TABLE v_active_notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_active_notifications TO anon;
GRANT ALL ON TABLE public.v_active_notifications TO authenticated;
GRANT ALL ON TABLE public.v_active_notifications TO service_role;

--
-- Name: TABLE v_upcoming_deadlines; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_upcoming_deadlines TO anon;
GRANT ALL ON TABLE public.v_upcoming_deadlines TO authenticated;
GRANT ALL ON TABLE public.v_upcoming_deadlines TO service_role;

--
-- Name: TABLE vendor_partners; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.vendor_partners TO anon;
GRANT ALL ON TABLE public.vendor_partners TO authenticated;
GRANT ALL ON TABLE public.vendor_partners TO service_role;

--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;

--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;

--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;

--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;

--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;

--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;
