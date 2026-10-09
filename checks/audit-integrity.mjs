#!/usr/bin/env node
// Requirements: PVE-AUD-001, PVE-STATE-001
import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const ROOT = process.cwd();
const COVERAGE = path.join(ROOT, 'audit', 'book-coverage.json');
const CLAIM_DIR = path.join(ROOT, 'audit', 'claims');

const COVERAGE_STATUSES = new Set(['NOT_STARTED','IN_PROGRESS','PARTIAL','AUDITED']);
const AXES = [
  'source_fact',
  'math',
  'assumptions',
  'dimensional',
  'relation_to_comparator',
  'invariance',
  'conservation',
  'experiment',
];
const WEAK_STATUSES = new Set(['OPEN','NOT_TESTED','GAP','NOT_APPLICABLE','CONDITIONAL']);
const STRONG_STATUSES = new Set([
  'VERIFIED',
  'CONTRADICTED',
  'SUPPORTED',
  'REJECTED',
  'EQUIVALENT',
  'NOVEL',
  'INCONSISTENT',
  'SATISFIED',
  'VIOLATED',
]);
const ALL_AXIS_STATUSES = new Set([...WEAK_STATUSES, ...STRONG_STATUSES]);

function fail(message) {
  console.error('AUDIT_INTEGRITY_FAIL:', message);
  process.exitCode = 1;
}
function nonEmptyString(v){ return typeof v === 'string' && v.trim().length > 0; }
function stringArray(v){ return Array.isArray(v) && v.every(nonEmptyString); }

const coverage = JSON.parse(await readFile(COVERAGE, 'utf8'));
if (coverage.schema !== 'pve-book-coverage/v1') fail('unsupported coverage schema');
if (!Array.isArray(coverage.sections) || coverage.sections.length === 0) {
  fail('coverage.sections must be a non-empty array');
}

const sectionIds = new Set();
let prevPage = 0;
for (let i=0; i<(coverage.sections ?? []).length; i++) {
  const s = coverage.sections[i];
  if (!s || typeof s !== 'object' || Array.isArray(s)) { fail(`section[${i}] must be object`); continue; }
  if (!/^NIK-[0-9]{4}$/.test(s.id ?? '')) fail(`section[${i}] invalid id`);
  if (sectionIds.has(s.id)) fail(`duplicate section id ${s.id}`);
  sectionIds.add(s.id);
  if (s.order !== i + 1) fail(`${s.id}: order must equal canonical position ${i+1}`);
  if (!Number.isSafeInteger(s.source_page) || s.source_page < 1) fail(`${s.id}: invalid source_page`);
  if (s.source_page < prevPage) fail(`${s.id}: source_page is non-monotone`);
  prevPage = s.source_page;
  if (!COVERAGE_STATUSES.has(s.status)) fail(`${s.id}: unknown coverage status ${s.status}`);
  if (!Array.isArray(s.evidence) || !s.evidence.every(nonEmptyString)) fail(`${s.id}: evidence must be string array`);
  if (s.status === 'AUDITED') {
    if (!nonEmptyString(s.disposition)) fail(`${s.id}: AUDITED requires disposition`);
    if (s.evidence.length === 0) fail(`${s.id}: AUDITED requires evidence`);
  }
}

let claimFiles=[];
try {
  claimFiles=(await readdir(CLAIM_DIR)).filter(x=>x.endsWith('.json')).sort();
} catch {}

const claimIds=new Set();
for (const file of claimFiles) {
  const full=path.join(CLAIM_DIR,file);
  if (!(await stat(full)).isFile()) continue;
  const c=JSON.parse(await readFile(full,'utf8'));
  if (c.schema !== 'pve-claim/v1') { fail(`${file}: unsupported claim schema`); continue; }
  if (!nonEmptyString(c.id)) fail(`${file}: claim id required`);
  if (claimIds.has(c.id)) fail(`${file}: duplicate claim id ${c.id}`);
  claimIds.add(c.id);
  if (!c.source || !Number.isSafeInteger(c.source.page) || c.source.page < 1 || !nonEmptyString(c.source.locator)) {
    fail(`${file}: exact source.page + source.locator required`);
  }
  if (!c.axes || typeof c.axes !== 'object' || Array.isArray(c.axes)) {
    fail(`${file}: axes object required`);
    continue;
  }
  for (const axis of AXES) {
    const a=c.axes[axis];
    if (!a || typeof a !== 'object' || Array.isArray(a)) { fail(`${file}: missing axis ${axis}`); continue; }
    if (!ALL_AXIS_STATUSES.has(a.status)) fail(`${file}: ${axis} unknown status ${a.status}`);
    if (!stringArray(a.evidence ?? [])) fail(`${file}: ${axis}.evidence must be string array`);
    if (STRONG_STATUSES.has(a.status) && (a.evidence ?? []).length === 0) {
      fail(`${file}: ${axis} status ${a.status} requires evidence`);
    }
  }
}

if (!process.exitCode) {
  console.log(`AUDIT_INTEGRITY_PASS sections=${coverage.sections.length} claims=${claimFiles.length}`);
}
