#!/usr/bin/env node
// Requirements: PVE-STATE-002
import { createHash } from "node:crypto";
import { access, readFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import process from "node:process";

const ROOT = process.cwd();
const MODEL_PATH = path.join(ROOT, "audit", "research-model.json");
const COVERAGE_PATH = path.join(ROOT, "audit", "book-coverage.json");
const PROJECTION_PATH = path.join(ROOT, "projections", "audit-report.model.json");
const BUILD_PATH = path.join(ROOT, "projections", "audit-report.build.json");
const TARGET_PATH = path.join(ROOT, "docs", "generated", "audit-report.pdf");

function fail(message) {
  console.error("AUDIT_REPORT_PROJECTION_FAIL:", message);
  process.exitCode = 1;
}
function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}
function argValue(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : null;
}

const repoGuardRoot = argValue("--repo-guard-root");
if (!repoGuardRoot) {
  fail("--repo-guard-root is required");
} else {
  const apiPath = path.resolve(repoGuardRoot, "dist", "projection-api.mjs");
  try {
    await access(apiPath);
    const api = await import(pathToFileURL(apiPath).href);
    const [modelBytes, coverageBytes, projectionText, buildText, outputBytes] = await Promise.all([
      readFile(MODEL_PATH),
      readFile(COVERAGE_PATH),
      readFile(PROJECTION_PATH, "utf8"),
      readFile(BUILD_PATH, "utf8"),
      readFile(TARGET_PATH),
    ]);

    const projection = JSON.parse(projectionText);
    const build = JSON.parse(buildText);
    const normalizedProjection = api.normalizeProjectionModel(projection);
    const normalizedBuild = api.normalizeProjectionBuildRecord(build, projection);
    const expectedModelIdentity = api.projectionModelIdentity(projection);

    if (normalizedBuild.model_identity !== expectedModelIdentity) {
      fail("build model_identity differs from repo-guard ProjectionModel identity");
    }

    const expectedSources = new Map([
      ["research-model", { path: "audit/research-model.json", digest: sha256(modelBytes) }],
      ["book-coverage", { path: "audit/book-coverage.json", digest: sha256(coverageBytes) }],
    ]);
    for (const [id, expected] of expectedSources) {
      const source = normalizedProjection.sources.find((item) => item.id === id);
      const identity = normalizedBuild.source_identities.find((item) => item.source_id === id);
      if (!source || !identity) {
        fail(`missing source identity: ${id}`);
        continue;
      }
      if (source.path !== expected.path) fail(`${id}: projection path drift`);
      if (identity.digest !== expected.digest) fail(`${id}: SHA-256 mismatch`);
    }

    if (normalizedProjection.target.path !== "docs/generated/audit-report.pdf" ||
        normalizedProjection.target.ownership !== "generated") {
      fail("projection target must be generated docs/generated/audit-report.pdf");
    }

    if (normalizedBuild.output_identity.digest !== sha256(outputBytes)) {
      fail("generated PDF SHA-256 mismatch");
    }
    if (!normalizedBuild.configuration_digest) {
      fail("configuration_digest is required");
    }

    for (const evidence of normalizedBuild.evidence) {
      try {
        await access(path.join(ROOT, evidence.ref));
      } catch {
        fail(`build evidence path does not exist: ${evidence.ref}`);
      }
    }

    if (!process.exitCode) {
      console.log(`AUDIT_REPORT_PROJECTION_PASS projection=${normalizedProjection.id} model=${expectedModelIdentity}`);
    }
  } catch (error) {
    fail(error instanceof Error ? error.message : String(error));
  }
}
