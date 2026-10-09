#!/usr/bin/env node
// Requirements: PVE-STATE-001
import { createHash } from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import process from "node:process";

export const AXES = [
  "source_fact",
  "math",
  "assumptions",
  "dimensional",
  "relation_to_comparator",
  "invariance",
  "conservation",
  "experiment",
];
export const STRONG_STATUSES = [
  "VERIFIED",
  "CONTRADICTED",
  "SUPPORTED",
  "REJECTED",
  "EQUIVALENT",
  "NOVEL",
  "INCONSISTENT",
  "SATISFIED",
  "VIOLATED",
];
const STRONG = new Set(STRONG_STATUSES);
const ROOT = process.cwd();
const MODEL_PATH = path.join(ROOT, "audit", "research-model.json");
const PROJECTION_PATH = path.join(ROOT, "projections", "verified-facts.model.json");
const BUILD_PATH = path.join(ROOT, "projections", "verified-facts.build.json");
const TARGET_PATH = path.join(ROOT, "docs", "generated", "verified-facts.md");

export const GENERATOR_CONTRACT = "pve/verified-facts-renderer/v3";
export const GENERATOR_TOOL_IDENTITY = "scripts/generate-verified-facts.mjs@v3";

function sha256(text) {
  return createHash("sha256").update(text, "utf8").digest("hex");
}

export function generatorConfigurationText() {
  return `${GENERATOR_CONTRACT}\naxes=${AXES.join(",")}\nstrong=${STRONG_STATUSES.join(",")}\n`;
}

export function generatorConfigurationDigest() {
  return sha256(generatorConfigurationText());
}

function normalizedProjectionModel(model) {
  return {
    schema: model.schema,
    id: model.id,
    sources: [...model.sources]
      .map((s) => ({ id: s.id, kind: s.kind, path: s.path, algorithm: s.algorithm }))
      .sort((a, b) => a.id.localeCompare(b.id)),
    target: model.target.ownership === "generated"
      ? { path: model.target.path, ownership: "generated" }
      : { path: model.target.path, ownership: model.target.ownership, locator: model.target.locator },
    generator: { contract_id: model.generator.contract_id },
    required_evidence: [...new Set(model.required_evidence)].sort(),
  };
}

export function projectionModelIdentity(model) {
  return sha256(JSON.stringify(normalizedProjectionModel(model)));
}

function escapeCell(value) {
  return String(value).replace(/\|/g, "\\|").replace(/\r?\n/g, " ");
}

function evidenceHref(evidence) {
  return evidence?.locator?.url ?? null;
}

function evidenceLink(evidence) {
  const href = evidenceHref(evidence);
  const title = escapeCell(evidence?.title ?? evidence?.id ?? "evidence");
  return href ? `[${title}](${href})` : title;
}

function strongResults(model) {
  const evidence = new Map((model.evidence ?? []).map((item) => [item.id, item]));
  const claims = [...(model.claims ?? [])].sort((a, b) =>
    String(a.section_id).localeCompare(String(b.section_id)) ||
    String(a.id).localeCompare(String(b.id))
  );
  const results = [];
  for (const claim of claims) {
    for (const axis of AXES) {
      const state = claim.axes?.[axis];
      if (!state || !STRONG.has(state.status)) continue;
      results.push({
        claim,
        axis,
        status: state.status,
        finding: state.finding ?? claim.statement,
        evidence: (state.evidence ?? []).map((id) => evidence.get(id)).filter(Boolean),
      });
    }
  }
  return results;
}

export function renderVerifiedFacts(model) {
  const results = strongResults(model);
  const usedEvidence = new Map();
  for (const result of results) {
    for (const item of result.evidence) usedEvidence.set(item.id, item);
  }

  const lines = [
    "# Проверенные факты и результаты",
    "",
    "> **GENERATED FILE — DO NOT EDIT MANUALLY.**",
    "> Каноническая модель: [`audit/research-model.json`](../../audit/research-model.json).",
    "> Этот документ является только детерминированной проекцией принятого состояния модели.",
    "",
    "## Сводка",
    "",
    `- Проверенных научных результатов: **${results.length}**`,
    `- Зарегистрированных утверждений: **${(model.claims ?? []).length}**`,
    `- Зарегистрированных свидетельств: **${(model.evidence ?? []).length}**`,
    "",
  ];

  if (results.length === 0) {
    lines.push(
      "Научный аудит книги ещё не начат, поэтому сильных проверенных результатов пока нет.",
      "",
      "## Проверенные результаты",
      "",
      "Пока нет результатов со сильным статусом.",
      "",
      "## Индекс свидетельств",
      "",
      "Пока нет свидетельств, используемых сильными результатами.",
      "",
    );
    return lines.join("\n");
  }

  lines.push(
    "Сильные статусы ниже означают проверенный результат на **конкретной оси**, а не глобальную истинность всего утверждения.",
    "",
    "## Проверенные результаты",
    "",
    "| Утверждение | Атрибуция | Проверенный результат | Раздел / источник | Зависимости | Ось | Статус | Свидетельства |",
    "| --- | --- | --- | --- | --- | --- | --- | --- |",
  );
  for (const result of results) {
    const claim = result.claim;
    const source = `${claim.section_id}; стр. ${claim.source.page}; ${claim.source.locator}`;
    const ev = result.evidence.map(evidenceLink).join("<br>") || "—";
    const dependencies = (claim.dependencies ?? []).map((id) => `\`${escapeCell(id)}\``).join("<br>") || "—";
    const attribution = `${claim.attribution.name}; ${claim.attribution.role}; ${claim.attribution.source_locator}`;
    lines.push(
      `| \`${escapeCell(claim.id)}\` — ${escapeCell(claim.statement)} | ${escapeCell(attribution)} | ${escapeCell(result.finding)} | ${escapeCell(source)} | ${dependencies} | \`${result.axis}\` | **${result.status}** | ${ev} |`,
    );
  }

  lines.push("", "## Индекс свидетельств", "");
  for (const item of [...usedEvidence.values()].sort((a, b) => a.id.localeCompare(b.id))) {
    const locator = item.locator ?? {};
    const exact = locator.kind === "repository"
      ? `; revision \`${locator.revision}\`; path \`${locator.path}\`${item.sha256 ? `; sha256 \`${item.sha256}\`` : ""}`
      : "";
    lines.push(`- \`${item.id}\` — ${evidenceLink(item)} — \`${item.kind}\`${exact}`);
  }
  lines.push("");
  return lines.join("\n");
}

export function createBuildRecord(modelText, projectionModel, outputText) {
  return {
    schema: "repo-guard/projection-build-record/v0",
    projection_id: projectionModel.id,
    model_identity: projectionModelIdentity(projectionModel),
    source_identities: [{
      source_id: "research-model",
      algorithm: "sha256",
      digest: sha256(modelText),
    }],
    generator: {
      contract_id: GENERATOR_CONTRACT,
      tool_identity: GENERATOR_TOOL_IDENTITY,
    },
    configuration_digest: generatorConfigurationDigest(),
    output_identity: {
      algorithm: "sha256",
      digest: sha256(outputText),
    },
    evidence: [
      { class: "deterministic-generator", ref: "scripts/generate-verified-facts.mjs" },
      { class: "repo-guard-projection", ref: "checks/verified-facts-projection.mjs" },
    ],
  };
}

async function main() {
  const check = process.argv.includes("--check");
  const modelText = await readFile(MODEL_PATH, "utf8");
  const model = JSON.parse(modelText);
  const projectionModel = JSON.parse(await readFile(PROJECTION_PATH, "utf8"));
  const outputText = renderVerifiedFacts(model);
  const buildText = JSON.stringify(createBuildRecord(modelText, projectionModel, outputText), null, 2) + "\n";

  if (!check) {
    await writeFile(TARGET_PATH, outputText, "utf8");
    await writeFile(BUILD_PATH , buildText, "utf8");
    console.log("VERIFIED_FACTS_GENERATED");
    return;
  }

  const [actualOutput, actualBuild] = await Promise.all([
    readFile(TARGET_PATH, "utf8"),
    readFile(BUILD_PATH, "utf8"),
  ]);
  if (actualOutput !== outputText) {
    console.error("VERIFIED_FACTS_STALE: docs/generated/verified-facts.md");
    process.exitCode = 1;
  }
  if (actualBuild !== buildText) {
    console.error("VERIFIED_FACTS_STALE: projections/verified-facts.build.json");
    process.exitCode = 1;
  }
  if (!process.exitCode) console.log("VERIFIED_FACTS_CURRENT");
}

const invoked = process.argv[1] ? path.resolve(process.argv[1]) : "";
if (invoked && fileURLToPath(import.meta.url) === invoked) await main();
