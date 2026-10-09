#!/usr/bin/env node
// Requirements: PVE-AUD-001, PVE-STATE-001
import { readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const ROOT = process.cwd();
const COVERAGE_PATH = path.join(ROOT, "audit", "book-coverage.json");
const MODEL_PATH = path.join(ROOT, "audit", "research-model.json");

const COVERAGE_STATUSES = new Set(["NOT_STARTED","IN_PROGRESS","PARTIAL","AUDITED"]);
const AXES = [
  "source_fact",
  "math",
  "assumptions",
  "dimensional",
  "relation_to_comparator",
  "invariance",
  "conservation",
  "experiment",
];
const WEAK_STATUSES = new Set(["OPEN","NOT_TESTED","GAP","NOT_APPLICABLE","CONDITIONAL"]);
const STRONG_STATUSES = new Set([
  "VERIFIED",
  "CONTRADICTED",
  "SUPPORTED",
  "REJECTED",
  "EQUIVALENT",
  "NOVEL",
  "INCONSISTENT",
  "SATISFIED",
  "VIOLATED",
]);
const ALL_AXIS_STATUSES = new Set([...WEAK_STATUSES, ...STRONG_STATUSES]);
const AUDITED_EXPLICIT_STATUSES = new Set(["OPEN","NOT_TESTED","GAP","CONDITIONAL"]);\nconst VERIFICATION_TRACKS = ["lean","julia","typescript"];\nconst VERIFICATION_STATUSES = new Set(["OPEN","PASS","FAIL","N_A"]);
const CLAIM_KINDS = new Set([
  "definition",
  "historical_fact",
  "source_fact",
  "mathematical_claim",
  "physical_claim",
  "experimental_claim",
  "numerical_result",
  "interpretation",
]);
const EVIDENCE_KINDS = new Set([
  "source",
  "formal_proof",
  "computation",
  "literature",
  "experiment",
  "repository_record",
  "review",
]);

function fail(message) {
  console.error("AUDIT_INTEGRITY_FAIL:", message);
  process.exitCode = 1;
}
function nonEmptyString(v) {
  return typeof v === "string" && v.trim().length > 0;
}
function stringArray(v) {
  return Array.isArray(v) && v.every(nonEmptyString);
}
function exactKeys(value, allowed, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    fail(`${label} must be object`);
    return false;
  }
  const extras = Object.keys(value).filter((key) => !allowed.includes(key));
  if (extras.length) fail(`${label}: unknown field(s): ${extras.join(", ")}`);
  return true;
}
function validHttps(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:";
  } catch {
    return false;
  }
}

const coverage = JSON.parse(await readFile(COVERAGE_PATH, "utf8"));
if (coverage.schema !== "pve-book-coverage/v1") fail("unsupported coverage schema");
if (!Array.isArray(coverage.sections) || coverage.sections.length === 0) {
  fail("coverage.sections must be a non-empty array");
}

const sectionIds = new Set();
const sectionById = new Map();
let prevPage = 0;
for (let i = 0; i < (coverage.sections ?? []).length; i++) {
  const s = coverage.sections[i];
  if (!s || typeof s !== "object" || Array.isArray(s)) { fail(`section[${i}] must be object`); continue; }
  if (!/^NIK-[0-9]{4}$/.test(s.id ?? "")) fail(`section[${i}] invalid id`);
  if (sectionIds.has(s.id)) fail(`duplicate section id ${s.id}`);
  sectionIds.add(s.id);
  sectionById.set(s.id, { ...s, index: i });
  if (s.order !== i + 1) fail(`${s.id}: order must equal canonical position ${i + 1}`);
  if (!Number.isSafeInteger(s.source_page) || s.source_page < 1) fail(`${s.id}: invalid source_page`);
  if (s.source_page < prevPage) fail(`${s.id}: source_page is non-monotone`);
  prevPage = s.source_page;
  if (!COVERAGE_STATUSES.has(s.status)) fail(`${s.id}: unknown coverage status ${s.status}`);
  if (!Array.isArray(s.evidence) || !s.evidence.every(nonEmptyString)) fail(`${s.id}: evidence must be string array`);
  if (s.status === "AUDITED") {
    if (!nonEmptyString(s.disposition)) fail(`${s.id}: AUDITED requires disposition`);
    if (s.evidence.length === 0) fail(`${s.id}: AUDITED requires evidence`);
  }
}

const model = JSON.parse(await readFile(MODEL_PATH, "utf8"));
exactKeys(model, ["schema","source_manifest","coverage_manifest","evidence","claims"], "research-model");
if (model.schema !== "pve-research-model/v2") fail("unsupported research model schema");
if (model.source_manifest !== "sources/nikolaev-2004/source.json") fail("research-model source_manifest must point to canonical source baseline");
if (model.coverage_manifest !== "audit/book-coverage.json") fail("research-model coverage_manifest must point to canonical coverage");
if (!Array.isArray(model.evidence)) fail("research-model.evidence must be array");
if (!Array.isArray(model.claims)) fail("research-model.claims must be array");

const evidenceById = new Map();
for (let i = 0; i < (model.evidence ?? []).length; i++) {
  const e = model.evidence[i];
  if (!exactKeys(e, ["id","kind","title","locator","sha256"], `evidence[${i}]`)) continue;
  if (!/^EVID-[0-9]{6}$/.test(e.id ?? "")) fail(`evidence[${i}]: invalid id`);
  if (evidenceById.has(e.id)) fail(`duplicate evidence id ${e.id}`);
  if (!EVIDENCE_KINDS.has(e.kind)) fail(`${e.id}: unknown evidence kind ${e.kind}`);
  if (!nonEmptyString(e.title)) fail(`${e.id}: title required`);
  if (!e.locator || typeof e.locator !== "object" || Array.isArray(e.locator)) {
    fail(`${e.id}: locator required`);
  } else if (e.locator.kind === "repository") {
    exactKeys(e.locator, ["kind","path","revision","url"], `${e.id}.locator`);
    if (!nonEmptyString(e.locator.path)) fail(`${e.id}: repository path required`);
    if (!/^[0-9a-f]{40}$/i.test(e.locator.revision ?? "")) fail(`${e.id}: exact repository revision required`);
    if (!validHttps(e.locator.url)) fail(`${e.id}: repository evidence URL must be https`);
  } else if (e.locator.kind === "url") {
    exactKeys(e.locator, ["kind","url"], `${e.id}.locator`);
    if (!validHttps(e.locator.url)) fail(`${e.id}: external evidence URL must be https`);
  } else {
    fail(`${e.id}: locator.kind must be repository or url`);
  }
  if (e.sha256 !== undefined && !/^[0-9a-f]{64}$/i.test(e.sha256)) fail(`${e.id}: sha256 must be 64 hex`);
  evidenceById.set(e.id, e);
}

const claimIds = new Set();
const claims = model.claims ?? [];
for (let i = 0; i < claims.length; i++) {
  const c = claims[i];
  if (!exactKeys(c, ["id","section_id","kind","statement","attribution","source","dependencies","axes","verification"], `claim[${i}]`)) continue;
  if (!/^NIK-[0-9]{4}-C[0-9]{3}$/.test(c.id ?? "")) fail(`claim[${i}]: invalid id`);
  if (claimIds.has(c.id)) fail(`duplicate claim id ${c.id}`);
  claimIds.add(c.id);
  if (!sectionIds.has(c.section_id)) fail(`${c.id}: unknown section_id ${c.section_id}`);
  if (!CLAIM_KINDS.has(c.kind)) fail(`${c.id}: unknown claim kind ${c.kind}`);
  if (!nonEmptyString(c.statement)) fail(`${c.id}: statement required`);
  if (!c.attribution || typeof c.attribution !== "object" || Array.isArray(c.attribution)) {
    fail(`${c.id}: attribution object required`);
  } else {
    exactKeys(c.attribution, ["name","role","source_locator"], `${c.id}.attribution`);
    if (!nonEmptyString(c.attribution.name)) fail(`${c.id}: attribution.name required`);
    if (!nonEmptyString(c.attribution.role)) fail(`${c.id}: attribution.role required`);
    if (!nonEmptyString(c.attribution.source_locator)) fail(`${c.id}: attribution.source_locator required`);
  }
  if (!c.source || typeof c.source !== "object" || Array.isArray(c.source)) {
    fail(`${c.id}: source object required`);
  } else {
    exactKeys(c.source, ["page","locator"], `${c.id}.source`);
    if (!Number.isSafeInteger(c.source.page) || c.source.page < 1 || !nonEmptyString(c.source.locator)) {
      fail(`${c.id}: exact source.page + source.locator required`);
    }
    const section = sectionById.get(c.section_id);
    if (section && Number.isSafeInteger(c.source.page) && c.source.page < section.source_page) {
      fail(`${c.id}: source page precedes section start page ${section.source_page}`);
    }
    const next = section ? coverage.sections[section.index + 1] : null;
    // A canonical section boundary may occur within one rendered PDF page.
    // The next section start page is admissible for the preceding section;
    // exact source.locator disambiguates material around the heading.
    if (section && next && next.source_page > section.source_page && c.source.page > next.source_page) {
      fail(`${c.id}: source page crosses beyond boundary page of next canonical section ${next.id}`);
    }
  }
  if (!stringArray(c.dependencies ?? [])) fail(`${c.id}: dependencies must be string array`);
  if (!c.verification || typeof c.verification !== "object" || Array.isArray(c.verification)) {
    fail(`${c.id}: verification object required`);
  } else {
    const verificationExtras = Object.keys(c.verification).filter((key) => !VERIFICATION_TRACKS.includes(key));
    if (verificationExtras.length) fail(`${c.id}: unknown verification track(s) ${verificationExtras.join(", ")}`);
    for (const track of VERIFICATION_TRACKS) {
      const v = c.verification[track];
      if (!v || typeof v !== "object" || Array.isArray(v)) {
        fail(`${c.id}: missing verification track ${track}`);
        continue;
      }
      exactKeys(v, ["status","finding","evidence"], `${c.id}.verification.${track}`);
      if (!VERIFICATION_STATUSES.has(v.status)) fail(`${c.id}: ${track} unknown verification status ${v.status}`);
      if (!nonEmptyString(v.finding)) fail(`${c.id}: ${track}.finding must be non-empty`);
      if (!stringArray(v.evidence ?? [])) fail(`${c.id}: ${track}.evidence must be evidence-id array`);
      for (const evidenceId of v.evidence ?? []) {
        if (!evidenceById.has(evidenceId)) fail(`${c.id}: ${track} references unknown evidence ${evidenceId}`);
      }
      if ((v.status === "PASS" || v.status === "FAIL") && (v.evidence ?? []).length === 0) {
        fail(`${c.id}: ${track} status ${v.status} requires evidence`);
      }
      if (v.status === "N_A" && (v.evidence ?? []).length !== 0) {
        fail(`${c.id}: ${track} N_A must not carry evidence`);
      }
    }
  }
  if (!c.axes || typeof c.axes !== "object" || Array.isArray(c.axes)) {
    fail(`${c.id}: axes object required`);
    continue;
  }
  const axisExtras = Object.keys(c.axes).filter((key) => !AXES.includes(key));
  if (axisExtras.length) fail(`${c.id}: unknown axis/axes ${axisExtras.join(", ")}`);
  for (const axis of AXES) {
    const a = c.axes[axis];
    if (!a || typeof a !== "object" || Array.isArray(a)) { fail(`${c.id}: missing axis ${axis}`); continue; }
    exactKeys(a, ["status","finding","evidence"], `${c.id}.${axis}`);
    if (!ALL_AXIS_STATUSES.has(a.status)) fail(`${c.id}: ${axis} unknown status ${a.status}`);
    if (a.finding !== null && a.finding !== undefined && !nonEmptyString(a.finding)) fail(`${c.id}: ${axis}.finding must be null or non-empty string`);
    if (!stringArray(a.evidence ?? [])) fail(`${c.id}: ${axis}.evidence must be evidence-id array`);
    for (const evidenceId of a.evidence ?? []) {
      if (!evidenceById.has(evidenceId)) fail(`${c.id}: ${axis} references unknown evidence ${evidenceId}`);
    }
    if (STRONG_STATUSES.has(a.status)) {
      if (!nonEmptyString(a.finding)) fail(`${c.id}: ${axis} status ${a.status} requires finding`);
      if ((a.evidence ?? []).length === 0) fail(`${c.id}: ${axis} status ${a.status} requires evidence`);
    }
  }
  if (STRONG_STATUSES.has(c.axes?.math?.status)) {
    const openTracks = VERIFICATION_TRACKS.filter((track) => c.verification?.[track]?.status === "OPEN");
    if (openTracks.length) {
      fail(`${c.id}: strong math status cannot have OPEN verification track(s): ${openTracks.join(", ")}`);
    }
  }
}

for (const c of claims) {
  for (const dependency of c.dependencies ?? []) {
    const resolvesClaim = claimIds.has(dependency);
    const resolvesSection = sectionIds.has(dependency);
    if (!resolvesClaim && !resolvesSection) fail(`${c.id}: unresolved dependency ${dependency}`);
    if (dependency === c.id || dependency === c.section_id) {
      fail(`${c.id}: self dependency is forbidden`);
    }
  }
}

for (const section of coverage.sections ?? []) {
  if (section.status !== "AUDITED") continue;
  const sectionClaims = claims.filter((claim) => claim.section_id === section.id);
  if (sectionClaims.length === 0) fail(`${section.id}: AUDITED section requires at least one registered claim`);
  for (const claim of sectionClaims) {
    for (const axis of AXES) {
      const state = claim.axes?.[axis];
      if (state && AUDITED_EXPLICIT_STATUSES.has(state.status) && !nonEmptyString(state.finding)) {
        fail(`${claim.id}: AUDITED section requires explicit finding for ${axis} status ${state.status}`);
      }
    }
  }
}

if (!process.exitCode) {
  const strongResults = claims.reduce((sum, claim) =>
    sum + AXES.filter((axis) => STRONG_STATUSES.has(claim.axes?.[axis]?.status)).length, 0);
  console.log(`AUDIT_INTEGRITY_PASS sections=${coverage.sections.length} claims=${claims.length} evidence=${evidenceById.size} strong_results=${strongResults}`);
}
