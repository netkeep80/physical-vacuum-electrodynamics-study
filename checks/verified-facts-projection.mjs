#!/usr/bin/env node
// Requirements: PVE-STATE-001
import { createHash } from "node:crypto";
import { access, readFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import process from "node:process";
import { generatorConfigurationDigest } from "../scripts/generate-verified-facts.mjs";

const ROOT = process.cwd();
const MODEL_PATH = path.join(ROOT, "audit", "research-model.json");
const PROJECTION_PATH = path.join(ROOT, "projections", "verified-facts.model.json");
const BUILD_PATH = path.join(ROOT, "projections", "verified-facts.build.json");
const TARGET_PATH = path.join(ROOT, "docs", "generated", "verified-facts.md");

function fail(message) {
  console.error("VERIFIED_FACTS_PROJECTION_FAIL:", message);
  process.exitCode = 1;
}
function sha256(text) {
  return createHash("sha256").update(text, "utf8").digest("hex");
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
    const [modelText, projectionText, buildText, outputText] = await Promise.all([
      readFile(MODEL_PATH, "utf8"),
      readFile(PROJECTION_PATH, "utf8"),
      readFile(BUILD_PATH, "utf8"),
      readFile(TARGET_PATH, "utf8"),
    ]);

    const projection = JSON.parse(projectionText);
    const build = JSON.parse(buildText);
    const normalizedProjection = api.normalizeProjectionModel(projection);
    const normalizedBuild = api.normalizeProjectionBuildRecord(build, projection);
    const expectedModelIdentity = api.projectionModelIdentity(projection);

    if (normalizedBuild.model_identity !== expectedModelIdentity) {
      fail("build model_identity differs from repo-guard ProjectionModel identity");
    }

    const source = normalizedProjection.sources.find((item) => item.id === "research-model");
    const sourceIdentity = normalizedBuild.source_identities.find((item) => item.source_id === "research-model");
    if (!source || !sourceIdentity) {
      fail("research-model source identity is missing");
    } else {
      const digest = sha256(modelText);
      if (source.path !== "audit/research-model.json") fail("projection source path drift");
      if (sourceIdentity.digest !== digest) fail("research-model SHA-256 mismatch");
    }

    if (normalizedProjection.target.path !== "docs/generated/verified-facts.md" ||
        normalizedProjection.target.ownership !== "generated") {
      fail("projection target must be generated docs/generated/verified-facts.md");
    }

    if (normalizedBuild.output_identity.digest !== sha256(outputText)) {
      fail("generated Markdown SHA-256 mismatch");
    }

    if (normalizedBuild.configuration_digest !== generatorConfigurationDigest()) {
      fail("generator configuration digest mismatch");
    }

    for (const evidence of normalizedBuild.evidence) {
      try {
        await access(path.join(ROOT, evidence.ref));
      } catch {
        fail(`build evidence path does not exist: ${evidence.ref}`);
      }
    }

    if (!process.exitCode) {
      console.log(`VERIFIED_FACTS_PROJECTION_PASS projection=${normalizedProjection.id} model=${expectedModelIdentity}`);
    }
  } catch (error) {
    fail(error instanceof Error ? error.message : String(error));
  }
}
