#!/usr/bin/env node
import assert from "node:assert/strict";
import { cp, mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const ROOT = process.cwd();
const coverageText = await readFile(path.join(ROOT, "audit", "book-coverage.json"), "utf8");
const modelText = await readFile(path.join(ROOT, "audit", "research-model.json"), "utf8");
const checker = path.join(ROOT, "checks", "audit-integrity.mjs");

async function run(mutator) {
  const dir = await mkdtemp(path.join(tmpdir(), "pve-model-contract-"));
  try {
    await mkdir(path.join(dir, "audit"), { recursive: true });
    await mkdir(path.join(dir, "checks"), { recursive: true });
    await writeFile(path.join(dir, "audit", "book-coverage.json"), coverageText, "utf8");
    const model = JSON.parse(modelText);
    mutator(model);
    await writeFile(path.join(dir, "audit", "research-model.json"), JSON.stringify(model, null, 2) + "\n", "utf8");
    await cp(checker, path.join(dir, "checks", "audit-integrity.mjs"));
    return spawnSync(process.execPath, ["checks/audit-integrity.mjs"], {
      cwd: dir,
      encoding: "utf8",
    });
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

const sectionDependency = await run((model) => {
  model.claims[0].dependencies = ["NIK-0002"];
});
assert.equal(sectionDependency.status, 0, sectionDependency.stderr || sectionDependency.stdout);

const unknownDependency = await run((model) => {
  model.claims[0].dependencies = ["NIK-9999"];
});
assert.notEqual(unknownDependency.status, 0);
assert.match(unknownDependency.stderr, /unresolved dependency NIK-9999/);

const selfSectionDependency = await run((model) => {
  model.claims[0].dependencies = [model.claims[0].section_id];
});
assert.notEqual(selfSectionDependency.status, 0);
assert.match(selfSectionDependency.stderr, /self dependency is forbidden/);

// Run the AUDITED case in its own fixture because coverage is separate from the model.
{
  const dir = await mkdtemp(path.join(tmpdir(), "pve-model-audited-"));
  try {
    await mkdir(path.join(dir, "audit"), { recursive: true });
    await mkdir(path.join(dir, "checks"), { recursive: true });
    const coverage = JSON.parse(coverageText);
    const section = coverage.sections.find((item) => item.id === "NIK-0001");
    section.status = "AUDITED";
    section.disposition = "self-test";
    section.evidence = ["audit/research-model.json"];
    await writeFile(path.join(dir, "audit", "book-coverage.json"), JSON.stringify(coverage, null, 2) + "\n", "utf8");
    const model = JSON.parse(modelText);
    const weakStatuses = new Set(["OPEN", "NOT_TESTED", "GAP", "CONDITIONAL"]);
    let erased = false;
    for (const claim of model.claims) {
      if (claim.section_id !== "NIK-0001") continue;
      for (const state of Object.values(claim.axes)) {
        if (weakStatuses.has(state.status) && typeof state.finding === "string" && state.finding.trim()) {
          state.finding = null;
          erased = true;
          break;
        }
      }
      if (erased) break;
    }
    assert.equal(erased, true, "fixture must contain an explicit weak finding to erase");
    await writeFile(path.join(dir, "audit", "research-model.json"), JSON.stringify(model, null, 2) + "\n", "utf8");
    await cp(checker, path.join(dir, "checks", "audit-integrity.mjs"));
    const result = spawnSync(process.execPath, ["checks/audit-integrity.mjs"], { cwd: dir, encoding: "utf8" });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /AUDITED section requires explicit finding/);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

console.log("RESEARCH_MODEL_CONTRACT_SELFTEST_PASS");
