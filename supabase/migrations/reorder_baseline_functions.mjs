/**
 * Reorder pg_dump sections for baseline_public.sql:
 *   core → functions → triggers → RLS enable → CREATE POLICY (all) → ALTER POLICY → COMMENT ON POLICY → ACL
 *
 * Usage: node reorder_baseline_functions.mjs
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PATH_IN = join(__dirname, "20260408000000_baseline_public.sql");
const PATH_OUT = join(__dirname, "20260408000000_baseline_public.sql");

const SEP = "\n--\n-- Name: ";

function splitObjects(rest) {
  const fr = rest.split(SEP);
  return [fr[0], ...fr.slice(1).map((f) => "--\n-- Name: " + f)];
}

function firstNameLine(section) {
  const m = section.match(/^--\n-- Name: (.+)$/m);
  return m ? m[1].trim() : "";
}

function parseType(nameLine) {
  const tm = nameLine.match(/Type:\s*([^;]+);/);
  return tm ? tm[1].trim() : "";
}

/**
 * pg_dump uses `Name: POLICY name ON table; Type: COMMENT` for COMMENT ON POLICY.
 */
function classify(section) {
  const nl = firstNameLine(section);
  const typ = parseType(nl);

  if (typ === "FUNCTION") return "function";
  if (typ === "COMMENT" && nl.startsWith("FUNCTION ")) return "function_comment";
  if (typ === "COMMENT" && /^\s*POLICY\s/i.test(nl)) return "policy_comment";

  if (typ === "POLICY") {
    if (/\bALTER\s+POLICY\b/i.test(section)) return "policy_alter";
    return "policy_create";
  }

  if (typ === "TRIGGER") return "trigger";
  if (typ === "ROW SECURITY") return "row_security";
  if (typ === "ACL") return "acl";
  if (typ === "DEFAULT ACL") return "default_acl";
  return "core";
}

function main() {
  const raw = readFileSync(PATH_IN, "utf8");
  const firstSep = raw.indexOf(SEP);
  if (firstSep === -1) throw new Error("separator not found");

  const preamble = raw.slice(0, firstSep);
  const rest = raw.slice(firstSep + 1);
  const sections = splitObjects(rest);

  const core = [];
  const rowSecurity = [];
  const functions = [];
  const policyCreate = [];
  const policyAlter = [];
  const policyComment = [];
  const triggers = [];
  const aclBlocks = [];

  for (const sec of sections) {
    const bucket = classify(sec);
    switch (bucket) {
      case "function":
      case "function_comment":
        functions.push(sec);
        break;
      case "policy_create":
        policyCreate.push(sec);
        break;
      case "policy_alter":
        policyAlter.push(sec);
        break;
      case "policy_comment":
        policyComment.push(sec);
        break;
      case "trigger":
        triggers.push(sec);
        break;
      case "row_security":
        rowSecurity.push(sec);
        break;
      case "acl":
      case "default_acl":
        aclBlocks.push(sec);
        break;
      default:
        core.push(sec);
    }
  }

  const ordered = [
    ...core,
    ...functions,
    ...triggers,
    ...rowSecurity,
    ...policyCreate,
    ...policyAlter,
    ...policyComment,
    ...aclBlocks,
  ];

  const body = ordered.join("\n");
  const out = preamble.replace(/\s+$/, "") + "\n" + body + (body.endsWith("\n") ? "" : "\n");

  writeFileSync(PATH_OUT, out, "utf8");
  console.log(
    "Wrote",
    PATH_OUT,
    "core=" + core.length,
    "fn=" + functions.length,
    "trig=" + triggers.length,
    "rls=" + rowSecurity.length,
    "pol+=" + policyCreate.length,
    "pol~=" + policyAlter.length,
    "pol//=" + policyComment.length,
    "acl=" + aclBlocks.length,
  );
}

main();
