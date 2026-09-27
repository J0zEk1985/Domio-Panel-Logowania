/**
 * Assemble supabase/schema_initial.sql from live Cloud catalog dumps (MCP execute_sql).
 * Usage: node scripts/assemble-schema.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const TOOLS = "C:\\Users\\jozef\\.cursor\\projects\\d-projekty-Domio-Serwis\\agent-tools";
const OUT = join(ROOT, "supabase", "schema_initial.sql");

function parseMcpFile(path) {
  const raw = readFileSync(path, "utf8");
  let text = raw;
  try {
    const outer = JSON.parse(raw);
    if (outer && typeof outer.result === "string") text = outer.result;
  } catch {
    /* already inner text */
  }
  const closeIdx = text.indexOf("</untrusted-data-");
  if (closeIdx < 0) throw new Error("Unclosed payload in " + path);
  const openRe = /<untrusted-data-[a-f0-9-]+>/gi;
  let start = -1;
  let m;
  while ((m = openRe.exec(text))) {
    const after = m.index + m[0].length;
    if (after < closeIdx) start = after;
  }
  if (start < 0) throw new Error("No payload in " + path);
  return JSON.parse(text.slice(start, closeIdx).trim());
}

function ident(name) {
  return '"' + String(name).replaceAll('"', '""') + '"';
}

function qTable(name) {
  const raw = String(name).replace(/^public\./, "").replaceAll('"', "");
  return "public." + ident(raw);
}

function unwrapList(parsed, keys = []) {
  if (Array.isArray(parsed)) {
    if (parsed.length === 1 && parsed[0] && typeof parsed[0] === "object") {
      for (const k of keys) {
        if (Array.isArray(parsed[0][k])) return parsed[0][k];
      }
    }
    return parsed;
  }
  if (parsed && typeof parsed === "object") {
    for (const k of keys) {
      if (Array.isArray(parsed[k])) return parsed[k];
    }
  }
  return [];
}

const ENUMS = [
  ["community_post_status", "active|completed|cancelled|deleted"],
  ["community_post_type", "offer|request|event|general"],
  ["company_category", "contractor|insurer|utility|other"],
  ["cooperation_link_status", "active|paused"],
  ["domio_module", "admin|cleaning|maintenance"],
  ["eboard_msg_status", "published|pending_moderation|archived"],
  ["eboard_msg_type", "official|advertisement|resident"],
  ["estate_member_status", "invited|accepted|rejected|withdrawn"],
  ["fleet_role", "admin|driver"],
  ["inspection_status", "positive|positive_with_defects|negative"],
  ["inspection_type", "building|building_5yr|chimney|gas|electrical|fire_safety|elevator_udt|elevator_electrical|separator|hydrophore|rainwater_pump|sewage_pump|mechanical_ventilation|car_platform|treatment_plant|garage_door|entrance_gate|barrier|co_lpg_detectors|other"],
  ["inspection_visit_kind", "primary|supplementary"],
  ["issue_marketplace_scope", "serving|all"],
  ["issue_priority_enum", "low|medium|high|critical"],
  ["issue_source_enum", "cleaning|admin_ui|dispatcher|serwis|tenant_qr|public_qr|email_ai|manual"],
  ["issue_status_enum", "new|open|pending_admin_approval|in_progress|waiting_for_parts|delegated|resolved|rejected|cancelled|pending_cleaning_review"],
  ["legal_entity_kind", "housing_community|housing_cooperative|property_manager|company"],
  ["legal_entity_lookup_status", "invalid_nip|exists_in_domio|not_in_domio"],
  ["legal_entity_status", "active|inactive|deregistered"],
  ["legal_entity_verification_status", "gus_verified|pending_manual|manually_verified"],
  ["mandate_role", "primary_operator|co_operator|legacy_operator|external_designee"],
  ["mandate_status", "invited|active|paused|superseded|declined"],
  ["policy_scope_enum", "majątkowe|oc_ogolne|oc_zarzadu"],
  ["priority_level", "low|medium|high|emergency"],
  ["property_contract_type", "cleaning|maintenance|administration|elevator|other"],
  ["property_task_priority", "low|medium|urgent"],
  ["property_task_status", "todo|in_progress|done"],
  ["property_task_visibility", "internal_only|board_visible"],
  ["succession_grant_access", "read|write"],
  ["succession_mode", "share_read|clone_to_successor|transfer_custody"],
  ["succession_resource", "issues|inspections|unit_inspections|contracts|residents|all"],
  ["succession_status", "proposed|accepted|completed|rejected|cancelled"],
  ["sync_status", "not_synced|pending|synced|error"],
  ["task_status", "pending|in_progress|done|cancelled"],
  ["task_type", "sop_standard|coordinator_single|long_term|employee_extra|extra_paid"],
  ["tire_set_location", "on_vehicle|warehouse|storage"],
  ["unit_inspection_status", "pending|completed|failed_no_access|failed_defects|rescheduled"],
  ["vehicle_document_kind", "policy|reg_doc"],
];

const BUCKETS = [
  { id: "cleaning-photos", public: false, limit: 10485760, mime: null },
  { id: "equipment-protocols", public: false, limit: 10485760, mime: ["image/jpeg", "image/png", "image/webp", "image/heic"] },
  { id: "issue_photos", public: false, limit: 10485760, mime: null },
  { id: "legal-acceptances", public: false, limit: 10485760, mime: ["application/pdf"] },
  { id: "photos", public: false, limit: 10485760, mime: null },
  { id: "property-issues", public: false, limit: 10485760, mime: null },
  { id: "resident-order-photos", public: false, limit: 10485760, mime: ["image/jpeg", "image/png", "image/webp", "image/heic"] },
  { id: "vehicle-docs", public: false, limit: 10485760, mime: ["application/pdf", "image/jpeg", "image/png", "image/webp", "image/heic", "application/octet-stream"] },
];

const FN_FILES = [
  "f2c27d5a-7699-4339-a2d2-c697374d18a4.txt",
  "d8aafefd-bc56-4b8c-9f5f-37a2635be510.txt",
  "c9666a08-20a2-4606-b444-5a342f376a57.txt",
  "b78c6af6-05b1-4694-b339-06beb12b3ef1.txt",
  "ffcc5382-a2b7-4eed-b708-23c692adb9b9.txt",
  "72be0535-a935-4967-a9b4-f7f96080ac20.txt",
  "7e2c33bc-639e-4400-b01e-df87c1ef850b.txt",
  "f429ee55-4d88-4cd3-bc06-e11a471caf24.txt",
  "1f4ff5ce-7f12-427a-b0f3-c784facd4f51.txt",
  "91106f5f-5349-4971-8ac4-233e6ac44bb1.txt",
  "28a6d176-6159-47d8-b23c-abcd610f7fea.txt",
];

const parts = [];
const push = (s) => parts.push(s);

push(`-- DOMIO schema_initial.sql
-- Live structure dump from Supabase Cloud project bmozhsbcwpufovwnmjeb (2026-09-21).
-- Schema only (tables, types, functions, triggers, RLS, grants) + empty storage buckets
-- + platform admin account jozefiakmar@gmail.com. No tenant/application data.
-- Apply once on a fresh self-hosted Supabase Postgres. Do not re-apply historical
-- supabase/migrations/*.sql after this file.
--
-- Import (on the VPS, Postgres is not exposed publicly):
--   docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - < supabase/schema_initial.sql
--   # or:  psql "$VPS_DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/schema_initial.sql

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS moddatetime WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO postgres, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO authenticated, service_role;
`);

push("-- Enums");
for (const [name, labels] of ENUMS) {
  const vals = labels.split("|").map((v) => "'" + v.replaceAll("'", "''") + "'").join(", ");
  push(`DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'public' AND t.typname = '${name}') THEN
    CREATE TYPE public.${ident(name)} AS ENUM (${vals});
  END IF;
END $$;`);
}

const tables = unwrapList(parseMcpFile(join(TOOLS, "f11c96bd-acfa-413b-9dc6-a3ff05f6754f.txt")), ["tables"]);
push("\n-- Tables");
for (const t of tables) {
  const cols = t.cols || [];
  const colSql = cols.map((c) => {
    let line = "  " + ident(c.name) + " " + c.type;
    if (c.identity === "ALWAYS") line += " GENERATED ALWAYS AS IDENTITY";
    else if (c.identity === "BY DEFAULT") line += " GENERATED BY DEFAULT AS IDENTITY";
    else if (c.default) line += " DEFAULT " + c.default;
    if (c.notnull) line += " NOT NULL";
    return line;
  });
  push(`CREATE TABLE IF NOT EXISTS ${qTable(t.table_name)} (\n${colSql.join(",\n")}\n);`);
}

const constraints = unwrapList(parseMcpFile(join(TOOLS, "5807ec1b-1d12-4d16-b6a6-83819cf219bd.txt")), ["constraints"]);
const byType = { p: [], u: [], c: [], x: [], f: [], other: [] };
for (const con of constraints) {
  const bucket = byType[con.contype] ? con.contype : "other";
  byType[bucket].push(con);
}
push("\n-- Constraints (non-FK then FK)");
for (const group of ["p", "u", "c", "x", "other", "f"]) {
  for (const con of byType[group]) {
    push(`DO $$ BEGIN
  ALTER TABLE ${qTable(con.table)} ADD CONSTRAINT ${ident(con.conname)} ${con.def};
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;`);
  }
}

const indexes = unwrapList(parseMcpFile(join(TOOLS, "0bccf2b3-9920-4c7a-9126-04bbda537e0f.txt")), ["indexes", "payload"]);
push("\n-- Indexes");
for (const idx of indexes) {
  let d = idx.indexdef;
  if (!d || !d.startsWith("CREATE ")) continue;
  d = d.replace(/^CREATE UNIQUE INDEX /, "CREATE UNIQUE INDEX IF NOT EXISTS ");
  d = d.replace(/^CREATE INDEX /, "CREATE INDEX IF NOT EXISTS ");
  if (!d.includes(" ON public.") && / ON [a-z_]/.test(d)) {
    d = d.replace(/ ON ([a-zA-Z_][a-zA-Z0-9_]*) /, " ON public.$1 ");
  }
  push(d + ";");
}

push("\n-- Functions");
const seenFn = new Set();
function emitFns(list) {
  for (const fn of list) {
    if (!fn || !fn.def) continue;
    const key = (fn.schema || "") + "." + (fn.name || "") + ":" + fn.def.slice(0, 120);
    if (seenFn.has(key)) continue;
    seenFn.add(key);
    let def = String(fn.def).trim();
    if (!def.endsWith(";")) def += ";";
    push(def);
  }
}
for (const f of FN_FILES) {
  const rows = parseMcpFile(join(TOOLS, f));
  const list = unwrapList(rows, ["chunk", "payload"]);
  emitFns(list);
}

push(`
CREATE OR REPLACE VIEW public.cleaner_recent_activity
WITH (security_invoker = true) AS
 SELECT id, task_id, user_id, action_type, notes, created_at
   FROM task_execution_logs
  WHERE user_id = auth.uid() AND created_at >= (now() - '24:00:00'::interval);

CREATE OR REPLACE VIEW public.user_app_access
WITH (security_invoker = true) AS
 SELECT DISTINCT m.user_id, os.app_id, a.name AS app_name, a.domain_url AS app_domain_url,
    a.api_url AS app_api_url, m.org_id, o.name AS org_name, os.status AS subscription_status
   FROM memberships m
     JOIN org_subscriptions os ON os.org_id = m.org_id
     JOIN applications a ON a.id = os.app_id
     JOIN organizations o ON o.id = m.org_id
  WHERE os.status = 'active'::text AND COALESCE(a.is_active, true) = true
    AND (os.expires_at IS NULL OR os.expires_at > now());

CREATE OR REPLACE VIEW public.v_upcoming_deadlines
WITH (security_invoker = true) AS
 SELECT v.id AS vehicle_id, v.org_id, v.reg_no, v.model, 'inspection'::text AS alert_type,
    v.next_inspection AS deadline_date, v.next_inspection - CURRENT_DATE AS days_left,
    p.full_name AS driver_name, p.email AS driver_email
   FROM vehicles v LEFT JOIN profiles p ON p.id = v.assigned_driver_id
UNION ALL
 SELECT v.id, v.org_id, v.reg_no, v.model, 'insurance'::text, v.insurance_expiry,
    v.insurance_expiry - CURRENT_DATE, p.full_name, p.email
   FROM vehicles v LEFT JOIN profiles p ON p.id = v.assigned_driver_id
UNION ALL
 SELECT v.id, v.org_id, v.reg_no, v.model, 'tire_change'::text, v.tire_change_date,
    v.tire_change_date - CURRENT_DATE, p.full_name, p.email
   FROM vehicles v LEFT JOIN profiles p ON p.id = v.assigned_driver_id
  WHERE v.tire_change_date IS NOT NULL;

CREATE OR REPLACE VIEW public.v_active_notifications
WITH (security_invoker = true) AS
 SELECT v.id AS vehicle_id, v.org_id, v.reg_no, v.model, v.assigned_driver_id,
    p.full_name AS driver_name, p.email AS driver_email, nt.type AS alert_type,
    nt.send_to, nt.days_before, nt.subject, nt.body_template, d.deadline_date,
    d.deadline_date - CURRENT_DATE AS days_left
   FROM vehicles v
     LEFT JOIN profiles p ON p.id = v.assigned_driver_id
     JOIN LATERAL (
       SELECT DISTINCT ON (t.type) t.type, t.subject, t.body_template, t.days_before, t.send_to
       FROM notification_templates t
       WHERE t.type = ANY (ARRAY['inspection'::text, 'insurance'::text, 'tire_change'::text])
         AND (t.org_id = v.org_id OR t.org_id IS NULL)
       ORDER BY t.type, (t.org_id IS NOT NULL) DESC
     ) nt ON true
     CROSS JOIN LATERAL (
       SELECT CASE nt.type
         WHEN 'inspection'::text THEN v.next_inspection
         WHEN 'insurance'::text THEN v.insurance_expiry
         WHEN 'tire_change'::text THEN v.tire_change_date
         ELSE NULL::date
       END AS deadline_date
     ) d
  WHERE d.deadline_date IS NOT NULL
    AND d.deadline_date >= CURRENT_DATE
    AND d.deadline_date <= (CURRENT_DATE + nt.days_before);
`);

push("\n-- Triggers");
const triggerLocal = JSON.parse(readFileSync(join(__dirname, "dump-src", "triggers.json"), "utf8"));
const triggers = triggerLocal.triggers || [];
for (const tr of triggers) {
  let d = tr.def.trim();
  if (!d.toUpperCase().includes(" ON PUBLIC.") && / ON [a-z_]/.test(d)) {
    d = d.replace(/ ON ([a-zA-Z_][a-zA-Z0-9_]*) /, " ON public.$1 ");
  }
  if (!d.endsWith(";")) d += ";";
  push("DROP TRIGGER IF EXISTS " + ident(tr.name || "trg") + " ON " + qTable(tr.table || "unknown") + ";");
  push(d);
}

const rlsTables = [
  "admin_contracts","applications","building_cooperation_links","building_inspections","ckob_credentials","ckob_property_mappings","ckob_sync_logs","cleaning_catalog","cleaning_clients","cleaning_extra_job_photos","cleaning_extra_jobs","cleaning_inventory","cleaning_locations","cleaning_staff","cleaning_tasks","cleaning_work_sessions","communities","community_board","community_comments","community_contact_board_entries","community_emergency_providers","companies","cookie_consents","duty_alerts","e_board_messages","equipment_assets","equipment_protocols","estate_members","estates","fleet_notification_dispatches","fuel_logs","inbound_email_ingest","inbound_reject_notices","inspection_campaign_assignees","inspection_campaign_days","inspection_campaigns","inspections","inspections_hybrid","internal_tasks","issue_email_dispatches","issue_lifecycle_events","legal_documents","legal_entities","legal_entity_audit_log","legal_welcome_dispatches","location_access","location_holidays","location_vendor_routing","locations","material_requests","memberships","notification_templates","offer_interactions","org_ai_usage_monthly","org_duty_eligible","org_duty_state","org_inbound_mailboxes","org_legal_entity_enrollments","org_serwis_billing_settings","org_serwis_protocol_counters","org_subscriptions","organizations","page_content","partner_offers","pricing_plans","profiles","promo_codes","property_checklists","property_contracts","property_inspections","property_issue_billing","property_issues","property_policies","property_sections","property_tasks","push_subscriptions","repair_logs","resident_configs","resident_order_catalog_item_locations","resident_order_catalog_items","resident_order_events","resident_order_settings","resident_orders","service_mandates","staff_equipment","staff_financial_adjustments","staff_payouts","staff_rate_history","succession_events","succession_share_grants","task_comments","task_execution_logs","task_step_logs","unit_inspection_records","user_consent_batches","user_consents","vehicle_documents","vehicle_tire_sets","vehicle_tire_swaps","vehicles","vendor_email_channels","vendor_email_inbound_events","vendor_email_inbound_templates","vendor_partners",
];
push("\n-- Row Level Security");
for (const name of rlsTables) {
  push(`ALTER TABLE ${qTable(name)} ENABLE ROW LEVEL SECURITY;`);
}

push("\n-- Policies");
const policies = unwrapList(parseMcpFile(join(TOOLS, "d19ca5a1-a017-485a-af7a-c5b279082215.txt")), ["policies"]);
for (const p of policies) {
  const schema = p.schema === "storage" ? "storage" : "public";
  const roles = String(p.roles || "{public}")
    .replace(/[{}]/g, "")
    .split(",")
    .map((r) => r.trim())
    .filter(Boolean)
    .map((r) => (r === "public" ? "public" : ident(r)))
    .join(", ");
  const permRaw = String(p.permissive || "PERMISSIVE").toUpperCase();
  const perm = permRaw === "RESTRICTIVE" || permRaw === "NO" ? "RESTRICTIVE" : "PERMISSIVE";
  let sql = `CREATE POLICY ${ident(p.name)} ON ${schema}.${ident(p.table)} AS ${perm} FOR ${p.cmd} TO ${roles}`;
  if (p.using) sql += ` USING (${p.using})`;
  if (p.check) sql += ` WITH CHECK (${p.check})`;
  sql += ";";
  push(`DROP POLICY IF EXISTS ${ident(p.name)} ON ${schema}.${ident(p.table)};`);
  push(sql);
}

push("\n-- Table grants");
const tableGrants = unwrapList(parseMcpFile(join(TOOLS, "6c2e1ebc-896c-46cb-a67d-b0865c74482b.txt")), ["table_grants"]);
const tgSeen = new Set();
for (const g of tableGrants) {
  const key = [g.schema, g.table, g.grantee, g.privilege].join("|");
  if (tgSeen.has(key)) continue;
  tgSeen.add(key);
  const who = g.grantee === "PUBLIC" ? "PUBLIC" : ident(g.grantee);
  push(`GRANT ${g.privilege} ON ${g.schema}.${ident(g.table)} TO ${who};`);
}

push("\n-- Function grants");
const fnGrants = unwrapList(parseMcpFile(join(TOOLS, "d8ae1838-8a75-4b78-80b3-1d731b4eafd6.txt")), ["fn_grants"]);
const fgSeen = new Set();
for (const g of fnGrants) {
  const args = g.args != null ? g.args : "";
  const key = [g.schema, g.name, args, g.grantee, g.privilege].join("|");
  if (fgSeen.has(key)) continue;
  fgSeen.add(key);
  const who = g.grantee === "PUBLIC" ? "PUBLIC" : ident(g.grantee);
  push(`GRANT ${g.privilege} ON FUNCTION ${g.schema}.${ident(g.name)}(${args}) TO ${who};`);
}

push("\n-- Empty storage buckets");
for (const b of BUCKETS) {
  const mime = b.mime ? `ARRAY[${b.mime.map((m) => "'" + m + "'").join(", ")}]::text[]` : "NULL";
  push(`INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('${b.id}', '${b.id}', ${b.public}, ${b.limit}, ${mime})
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;`);
}

push(`
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.property_issues;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Platform admin (same Cloud user id + password hash). JWT secrets on VPS differ,
-- so the user must sign in again after cutover.
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'f39c6c7c-b9db-4f1a-aada-1a6c301caba8',
  'authenticated', 'authenticated',
  'jozefiakmar@gmail.com',
  '$2a$10$XTyDtvxMKf/oqnTmV2s6Ve9lKdDYYhXDW4ombyl3eHu6nkDBM8Bga',
  now(),
  '', '', '', '',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(), now(), false, false
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  encrypted_password = EXCLUDED.encrypted_password,
  email_confirmed_at = COALESCE(auth.users.email_confirmed_at, EXCLUDED.email_confirmed_at);

INSERT INTO auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) VALUES (
  'cbb7fa30-3c13-42dc-8dfa-c7a7a73b04b6',
  'f39c6c7c-b9db-4f1a-aada-1a6c301caba8',
  'f39c6c7c-b9db-4f1a-aada-1a6c301caba8',
  '{"sub":"f39c6c7c-b9db-4f1a-aada-1a6c301caba8","email":"jozefiakmar@gmail.com","email_verified":true,"phone_verified":false}'::jsonb,
  'email', now(), now(), now()
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, full_name, email, platform_role, account_type, is_first_login, fleet_role)
VALUES (
  'f39c6c7c-b9db-4f1a-aada-1a6c301caba8',
  'Marcin Józefiak',
  'jozefiakmar@gmail.com',
  'admin',
  'standard',
  false,
  'admin'
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  platform_role = 'admin',
  fleet_role = COALESCE(public.profiles.fleet_role, 'admin');

SELECT cron.unschedule(jobid) FROM cron.job
  WHERE jobname IN ('generate-sop-tasks-nightly', 'prune-expired-succession-grants');
SELECT cron.schedule(
  'prune-expired-succession-grants',
  '15 * * * *',
  $cron$SELECT private.prune_expired_succession_grants()$cron$
);
-- After setting SOP_CRON_SECRET on the VPS, enable:
-- SELECT cron.schedule('generate-sop-tasks-nightly', '5 0 * * *',
--   $cron$SELECT net.http_post(
--     url := 'https://db.j0zek.pl/functions/v1/generate-sop-tasks',
--     headers := '{"Content-Type":"application/json","x-domio-cron-secret":"CHANGE_ME"}'::jsonb,
--     body := '{}'::jsonb
--   );$cron$);

COMMIT;
`);

mkdirSync(join(ROOT, "supabase"), { recursive: true });
writeFileSync(OUT, parts.join("\n") + "\n", "utf8");
console.log(
  "Wrote",
  OUT,
  "bytes=",
  Buffer.byteLength(parts.join("\n")),
  "tables=",
  tables.length,
  "constraints=",
  constraints.length,
  "indexes=",
  indexes.length,
  "functions=",
  seenFn.size,
  "policies=",
  policies.length,
  "triggers=",
  triggers.length,
  "grants_fn=",
  fgSeen.size
);
