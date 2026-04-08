/**
 * Strip Supabase Cloud pg_dump for self-hosted: keep public schema application DDL.
 *
 * Usage:
 *   node strip_supabase_dump.mjs [input.sql] [output.sql]
 *
 * Defaults:
 *   input  = ./20260408000000_baseline.sql.sql (full cloud dump)
 *   output = ./20260408000000_baseline_public.sql (cleaned; never overwrites input)
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

const FORBIDDEN_SCHEMAS = new Set([
  "auth",
  "storage",
  "realtime",
  "pgsodium",
  "graphql",
  "graphql_public",
  "pgbouncer",
  "vault",
  "extensions",
  "cron",
  "net",
]);

/** Built-ins (user examples) + extensions tied to Cloud-only / forbidden schemas. */
const EXTENSIONS_TO_STRIP = new Set([
  "pgcrypto",
  "uuid-ossp",
  "pg_stat_statements",
  "pg_cron",
  "moddatetime",
  "pg_graphql",
  "supabase_vault",
]);

const SEP = "\n--\n-- Name: ";

function parseNameLine(section) {
  const m = section.match(/^--\n-- Name: (.+)$/m);
  if (!m) return { schema: null, typ: null, nameLine: "" };
  const nameLine = m[1].trim();
  const sm = nameLine.match(/Schema:\s*([^;]+);/);
  const tm = nameLine.match(/Type:\s*([^;]+);/);
  return {
    schema: sm ? sm[1].trim() : null,
    typ: tm ? tm[1].trim() : null,
    nameLine,
  };
}

function extensionNameCreate(nameLine) {
  const m = nameLine.trim().match(/^([^;]+);\s*Type:\s*EXTENSION\b/);
  return m ? m[1].trim().replace(/^"|"$/g, "") : null;
}

function extensionNameComment(nameLine) {
  const m = nameLine.trim().match(/^EXTENSION\s+(?:"([^"]+)"|(\S+))\s*;/);
  if (!m) return null;
  return (m[1] || m[2] || "").trim();
}

function shouldKeepSection(section) {
  const { schema, typ, nameLine } = parseNameLine(section);
  const body = section;

  if (schema && schema !== "-" && FORBIDDEN_SCHEMAS.has(schema)) return false;
  if (schema === "public") return true;

  if (schema === "-") {
    if (typ === "PUBLICATION") return false;
    if (typ === "PUBLICATION TABLE") {
      return (
        body.includes("ADD TABLE ONLY public.") ||
        body.includes("ADD TABLE public.")
      );
    }
    if (typ === "EVENT TRIGGER") return false;
    if (typ === "EXTENSION") {
      const ext = extensionNameCreate(nameLine);
      return !(ext && EXTENSIONS_TO_STRIP.has(ext));
    }
    if (typ === "COMMENT" && nameLine.startsWith("EXTENSION ")) {
      const ext = extensionNameComment(nameLine);
      return !(ext && EXTENSIONS_TO_STRIP.has(ext));
    }
    if (typ === "SCHEMA") {
      const sm = nameLine.match(/^([^;]+);\s*Type:\s*SCHEMA\b/);
      if (sm && FORBIDDEN_SCHEMAS.has(sm[1].trim())) return false;
      return true;
    }
    if (typ === "ACL") {
      const sm = nameLine.match(/^SCHEMA\s+(\w+);\s*Type:\s*ACL\b/);
      if (sm) return !FORBIDDEN_SCHEMAS.has(sm[1]);
      return true;
    }
  }

  if (schema && schema !== "-" && !FORBIDDEN_SCHEMAS.has(schema)) return true;
  return false;
}

/** Preamble only: pg_dump session knobs (not SET inside function bodies). */
function stripPreambleSession(text) {
  return text
    .split("\n")
    .filter((line) => {
      const s = line.trim();
      if (s.startsWith("\\")) return false;
      if (/^SET\s+/i.test(line)) return false;
      if (/^SELECT\s+pg_catalog\.set_config\s*\(/i.test(line)) return false;
      return true;
    })
    .join("\n");
}

/** Trailing psql meta (e.g. \\unrestrict) may live inside the last object chunk. */
function stripBackslashMeta(text) {
  return text
    .split("\n")
    .filter((line) => !line.trim().startsWith("\\"))
    .join("\n");
}

function splitDumpObjects(rest) {
  const frags = rest.split(SEP);
  if (frags.length === 0) return [];
  return [frags[0], ...frags.slice(1).map((f) => "--\n-- Name: " + f)];
}

function stripDump(raw) {
  const firstSep = raw.indexOf(SEP);
  if (firstSep === -1) throw new Error("Unexpected dump format: separator not found");

  const preamble = raw.slice(0, firstSep);
  const rest = raw.slice(firstSep + 1);
  const sections = splitDumpObjects(rest);

  const kept = [stripPreambleSession(preamble).replace(/\s+$/, "")];
  for (const sec of sections) {
    if (shouldKeepSection(sec)) {
      const cleaned = stripBackslashMeta(sec).replace(/\s+$/, "");
      if (cleaned.trim()) kept.push(cleaned);
    }
  }

  let out = kept.filter((k) => k.trim()).join("\n\n");
  out =
    "-- DOMIO baseline (public schema only). Cleaned from Supabase Cloud pg_dump for self-hosted.\n" +
    "-- Removed: platform schemas (auth, storage, realtime, extensions, graphql, vault, …), " +
    "psql \\-meta lines, preamble SET/session lines, selected CREATE EXTENSION.\n\n" +
    out +
    "\n";
  return out;
}

const defaultIn = join(__dirname, "20260408000000_baseline.sql.sql");
const defaultOut = join(__dirname, "20260408000000_baseline_public.sql");
const inputPath = process.argv[2] || defaultIn;
const outputPath = process.argv[3] || defaultOut;

if (!existsSync(inputPath)) {
  console.error("Input not found:", inputPath);
  process.exit(1);
}
if (inputPath === outputPath) {
  console.error("Refusing to read and write the same path:", inputPath);
  process.exit(1);
}

const raw = readFileSync(inputPath, "utf8");
const out = stripDump(raw);
writeFileSync(outputPath, out, "utf8");
console.log("Wrote", outputPath, "(" + out.split("\n").length + " lines)");
