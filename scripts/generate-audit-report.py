#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import re
import sys
from pathlib import Path
from typing import Any
from xml.sax.saxutils import escape

from reportlab import Version as REPORTLAB_VERSION, rl_config
rl_config.invariant = 1

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import LongTable, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

ROOT = Path.cwd()
MODEL_PATH = ROOT / "audit" / "research-model.json"
COVERAGE_PATH = ROOT / "audit" / "book-coverage.json"
PROJECTION_PATH = ROOT / "projections" / "audit-report.model.json"
BUILD_PATH = ROOT / "projections" / "audit-report.build.json"
TARGET_PATH = ROOT / "docs" / "generated" / "audit-report.pdf"

GENERATOR_CONTRACT = "pve/sequential-audit-pdf/v1"
GENERATOR_TOOL_IDENTITY = "scripts/generate-audit-report.py@v1"
EXPECTED_REPORTLAB = "4.4.9"
CORE_START_ORDER = 7

REGULAR_FONT = Path(os.environ.get(
    "PVE_REPORT_FONT_REGULAR",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
))
BOLD_FONT = Path(os.environ.get(
    "PVE_REPORT_FONT_BOLD",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
))

AXES = [
    "source_fact",
    "math",
    "assumptions",
    "dimensional",
    "relation_to_comparator",
    "invariance",
    "conservation",
    "experiment",
]

AXIS_RU = {
    "source_fact": "Факт источника",
    "math": "Математика",
    "assumptions": "Предпосылки",
    "dimensional": "Размерности",
    "relation_to_comparator": "Отношение к сравнительной теории",
    "invariance": "Инвариантность",
    "conservation": "Законы сохранения",
    "experiment": "Эксперимент",
}

STATUS_RU = {
    "OPEN": "открыто",
    "NOT_TESTED": "не проверено",
    "GAP": "пробел",
    "NOT_APPLICABLE": "не применимо",
    "CONDITIONAL": "условно",
    "VERIFIED": "проверено",
    "CONTRADICTED": "противоречит",
    "SUPPORTED": "поддержано",
    "REJECTED": "отвергнуто",
    "EQUIVALENT": "эквивалентно",
    "NOVEL": "новое",
    "INCONSISTENT": "несогласованно",
    "SATISFIED": "выполнено",
    "VIOLATED": "нарушено",
}

COVERAGE_RU = {
    "NOT_STARTED": "не начато",
    "IN_PROGRESS": "в работе",
    "PARTIAL": "частично проверено",
    "AUDITED": "проверено",
}

KIND_RU = {
    "definition": "определение",
    "historical_fact": "исторический факт",
    "source_fact": "факт источника",
    "mathematical_claim": "математическое утверждение",
    "physical_claim": "физическое утверждение",
    "experimental_claim": "экспериментальное утверждение",
    "numerical_result": "численный результат",
    "interpretation": "интерпретация",
}

EVIDENCE_RU = {
    "source": "источник",
    "formal_proof": "формальное доказательство",
    "computation": "вычислительная проверка",
    "literature": "литературный источник",
    "experiment": "эксперимент",
    "repository_record": "запись репозитория",
    "review": "независимая проверка",
}

ROLE_RU = {
    "book_author": "автор книги",
    "foreword_author": "автор предисловия",
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def json_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def compact_json_bytes(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")


def normalize_projection_model(model: dict[str, Any]) -> dict[str, Any]:
    sources = [
        {
            "id": s["id"],
            "kind": s["kind"],
            "path": s["path"],
            "algorithm": s["algorithm"],
        }
        for s in model["sources"]
    ]
    sources.sort(key=lambda x: x["id"])
    target = model["target"]
    normalized_target = {
        "path": target["path"],
        "ownership": target["ownership"],
    }
    if target["ownership"] != "generated" and "locator" in target:
        normalized_target["locator"] = target["locator"]
    return {
        "schema": model["schema"],
        "id": model["id"],
        "sources": sources,
        "target": normalized_target,
        "generator": {"contract_id": model["generator"]["contract_id"]},
        "required_evidence": sorted(set(model.get("required_evidence", []))),
    }


def projection_model_identity(model: dict[str, Any]) -> str:
    return sha256_bytes(compact_json_bytes(normalize_projection_model(model)))


def configuration_text() -> str:
    return (
        f"contract={GENERATOR_CONTRACT}\n"
        f"tool={GENERATOR_TOOL_IDENTITY}\n"
        f"reportlab={REPORTLAB_VERSION}\n"
        f"font_regular_sha256={sha256_file(REGULAR_FONT)}\n"
        f"font_bold_sha256={sha256_file(BOLD_FONT)}\n"
        f"core_start_order={CORE_START_ORDER}\n"
        "language=ru\n"
        "layout=sequential-audit-v1\n"
    )


def configuration_digest() -> str:
    return sha256_bytes(configuration_text().encode("utf-8"))


def clean_text(value: Any) -> str:
    if value is None:
        return ""
    text = str(value).replace("—", "-").replace("–", "-")
    text = text.replace("discriminating power", "различающая способность")
    text = text.replace("verdict", "заключение")
    text = re.sub(r"\bp\.(\d+)\b", r"стр. \1", text)
    text = text.replace(" bottom", ", нижняя часть")
    text = text.replace(" top", ", верхняя часть")
    text = text.replace(" before §2 heading", ", до заголовка §2")
    return text


def ptext(value: Any) -> str:
    return escape(clean_text(value)).replace("\n", "<br/>")


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "RussianTitle", parent=base["Title"], fontName="PVEDejaVuBold",
            fontSize=20, leading=25, alignment=TA_CENTER, spaceAfter=12,
        ),
        "subtitle": ParagraphStyle(
            "RussianSubtitle", parent=base["Normal"], fontName="PVEDejaVu",
            fontSize=11, leading=16, alignment=TA_CENTER, spaceAfter=8,
        ),
        "h1": ParagraphStyle(
            "RussianH1", parent=base["Heading1"], fontName="PVEDejaVuBold",
            fontSize=15, leading=19, spaceBefore=10, spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "RussianH2", parent=base["Heading2"], fontName="PVEDejaVuBold",
            fontSize=12, leading=16, spaceBefore=8, spaceAfter=6,
        ),
        "h3": ParagraphStyle(
            "RussianH3", parent=base["Heading3"], fontName="PVEDejaVuBold",
            fontSize=10, leading=14, spaceBefore=6, spaceAfter=4,
        ),
        "body": ParagraphStyle(
            "RussianBody", parent=base["BodyText"], fontName="PVEDejaVu",
            fontSize=9, leading=13, spaceAfter=5,
        ),
        "small": ParagraphStyle(
            "RussianSmall", parent=base["BodyText"], fontName="PVEDejaVu",
            fontSize=7.5, leading=10.5, spaceAfter=3,
        ),
        "small_bold": ParagraphStyle(
            "RussianSmallBold", parent=base["BodyText"], fontName="PVEDejaVuBold",
            fontSize=7.5, leading=10.5, spaceAfter=2,
        ),
    }


def page_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("PVEDejaVu", 7)
    canvas.drawString(18 * mm, 10 * mm, "Сформировано из канонической исследовательской модели")
    canvas.drawRightString(A4[0] - 18 * mm, 10 * mm, f"Страница {doc.page}")
    canvas.restoreState()


def evidence_summary(eid: str, evidence_by_id: dict[str, dict[str, Any]], styles) -> Paragraph:
    e = evidence_by_id.get(eid)
    if not e:
        return Paragraph(ptext(f"{eid}: свидетельство не найдено в модели"), styles["small"])
    kind = EVIDENCE_RU.get(e.get("kind"), "свидетельство")
    locator = e.get("locator") or {}
    chunks = [f"{eid}: {kind}"]
    if locator.get("kind") == "repository":
        if locator.get("revision"):
            chunks.append(f"ревизия {locator['revision']}")
        if locator.get("path"):
            chunks.append(f"путь {locator['path']}")
    if e.get("sha256"):
        chunks.append(f"SHA-256 {e['sha256']}")
    url = locator.get("url")
    text = "; ".join(chunks)
    if isinstance(url, str) and url.startswith("https://"):
        return Paragraph(f"{ptext(text)}; <link href=\"{escape(url)}\">ссылка</link>", styles["small"])
    return Paragraph(ptext(text), styles["small"])


def verification_matrix(claim: dict[str, Any], evidence_by_id: dict[str, dict[str, Any]]) -> list[list[str]]:
    all_evidence_ids: list[str] = []
    for axis in AXES:
        all_evidence_ids.extend((claim.get("axes", {}).get(axis, {}) or {}).get("evidence", []) or [])
    evidence = [evidence_by_id[eid] for eid in all_evidence_ids if eid in evidence_by_id]

    math_status = ((claim.get("axes") or {}).get("math") or {}).get("status")
    required = claim.get("kind") in {"mathematical_claim", "numerical_result"} or math_status not in {None, "NOT_APPLICABLE"}
    if not required:
        return [
            ["Lean 4", "не требуется для данного утверждения"],
            ["Julia", "не требуется для данного утверждения"],
            ["TypeScript", "не требуется для данного утверждения"],
        ]

    def ids_for(predicate):
        ids = []
        for e in evidence:
            title = str(e.get("title", ""))
            if predicate(e, title):
                ids.append(e["id"])
        return ids

    lean = ids_for(lambda e, title: e.get("kind") == "formal_proof" or "Lean" in title)
    ts = ids_for(lambda e, title: "TypeScript" in title or "TS regression" in title)
    julia = ids_for(lambda e, title: (e.get("kind") == "computation" and "TypeScript" not in title and "TS regression" not in title) or "Julia" in title)

    def state(ids):
        return "зафиксировано: " + ", ".join(ids) if ids else "не зарегистрировано"

    return [["Lean 4", state(lean)], ["Julia", state(julia)], ["TypeScript", state(ts)]]


def build_pdf(model: dict[str, Any], coverage: dict[str, Any]) -> bytes:
    if REPORTLAB_VERSION != EXPECTED_REPORTLAB:
        raise RuntimeError(f"Требуется reportlab {EXPECTED_REPORTLAB}, получено {REPORTLAB_VERSION}")
    for p in (REGULAR_FONT, BOLD_FONT):
        if not p.is_file():
            raise RuntimeError(f"Не найден шрифт для русского PDF: {p}")

    pdfmetrics.registerFont(TTFont("PVEDejaVu", str(REGULAR_FONT)))
    pdfmetrics.registerFont(TTFont("PVEDejaVuBold", str(BOLD_FONT)))

    styles = make_styles()
    output = io.BytesIO()
    doc = SimpleDocTemplate(
        output, pagesize=A4, rightMargin=18 * mm, leftMargin=18 * mm,
        topMargin=17 * mm, bottomMargin=17 * mm,
        title="Независимый аудит теоретических построений Г. В. Николаева",
        author="physical-vacuum-electrodynamics-study",
        subject="Последовательный аудит книги с опорой на каноническую модель",
    )

    evidence_by_id = {e["id"]: e for e in model.get("evidence", [])}
    claims_by_section: dict[str, list[dict[str, Any]]] = {}
    for claim in model.get("claims", []):
        claims_by_section.setdefault(claim["section_id"], []).append(claim)
    for claims in claims_by_section.values():
        claims.sort(key=lambda c: c["id"])

    core_sections = [s for s in coverage.get("sections", []) if s.get("order", 0) >= CORE_START_ORDER]
    counts = {key: 0 for key in COVERAGE_RU}
    for s in core_sections:
        counts[s["status"]] = counts.get(s["status"], 0) + 1

    story = []
    story.append(Spacer(1, 22 * mm))
    story.append(Paragraph("Независимый аудит теоретических построений Г. В. Николаева", styles["title"]))
    story.append(Paragraph("«Электродинамика физического вакуума» (2004)", styles["subtitle"]))
    story.append(Spacer(1, 8 * mm))
    story.append(Paragraph("Последовательный научный отчёт, автоматически сформированный из принятой исследовательской модели.", styles["subtitle"]))
    story.append(Paragraph("Основной аудит начинается с NIK-0007, стр. 81. Материалы до стр. 81 не являются блокирующей частью основного научного маршрута.", styles["subtitle"]))
    story.append(Spacer(1, 8 * mm))
    story.append(Paragraph(
        f"SHA-256 модели: {sha256_file(MODEL_PATH)}<br/>SHA-256 покрытия книги: {sha256_file(COVERAGE_PATH)}",
        styles["small"],
    ))
    story.append(PageBreak())

    story.append(Paragraph("Методика проверки", styles["h1"]))
    methodology = [
        "Цель исследования - не поиск расхождений с общепринятой теорией, а скрупулёзная проверка собственного пути Николаева: постановки задач, определений, постулатов, логических переходов, преобразований, расчётов и выводов.",
        "Расхождение с уравнениями Максвелла или релятивистской электродинамикой само по себе не считается ошибкой. Оно лишь отмечает точку, где теория Николаева вводит новое предположение, объект или математический член.",
        "Для каждой существенной математической задачи или формулы действует тройная проверка: Lean 4 - формальная сторона; Julia - независимое вычислительное воспроизведение; TypeScript - численные регрессионные тесты и проверки свойств. Если слой неприменим, это должно быть зафиксировано явно.",
        "Экспериментальная проверка рассматривается после восстановления и проверки соответствующей теоретической цепочки.",
        "Статус «пробел» означает отсутствие необходимого звена доказательства или определения и не равнозначен утверждению «неверно».",
    ]
    for item in methodology:
        story.append(Paragraph(ptext(item), styles["body"]))

    story.append(Paragraph("Состояние основного маршрута", styles["h1"]))
    story.append(Paragraph(
        ptext(
            f"Всего разделов основного маршрута: {len(core_sections)}; не начато: {counts.get('NOT_STARTED', 0)}; "
            f"в работе: {counts.get('IN_PROGRESS', 0)}; частично проверено: {counts.get('PARTIAL', 0)}; "
            f"проверено: {counts.get('AUDITED', 0)}."
        ),
        styles["body"],
    ))

    register_data = [[
        Paragraph("ID", styles["small_bold"]),
        Paragraph("Страница", styles["small_bold"]),
        Paragraph("Раздел", styles["small_bold"]),
        Paragraph("Состояние", styles["small_bold"]),
    ]]
    for s in core_sections:
        register_data.append([
            Paragraph(ptext(s["id"]), styles["small"]),
            Paragraph(ptext(s["source_page"]), styles["small"]),
            Paragraph(ptext(s["title"]), styles["small"]),
            Paragraph(ptext(COVERAGE_RU.get(s["status"], s["status"])), styles["small"]),
        ])
    register = LongTable(register_data, colWidths=[25*mm, 18*mm, 103*mm, 30*mm], repeatRows=1)
    register.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.25, colors.grey),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#EDEDED")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 3),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    story.append(register)
    story.append(PageBreak())

    story.append(Paragraph("Последовательный аудит", styles["h1"]))
    for s in core_sections:
        claims = claims_by_section.get(s["id"], [])
        if s["status"] == "NOT_STARTED" and not claims:
            continue

        story.append(Paragraph(f"{ptext(s['id'])}. {ptext(s['title'])}", styles["h1"]))
        chapter_bits = [f"Начальная страница: {s['source_page']}", f"Состояние: {COVERAGE_RU.get(s['status'], s['status'])}"]
        if s.get("chapter") is not None:
            chapter_bits.append(f"Глава: {s['chapter']}")
        if s.get("section") is not None:
            chapter_bits.append(f"Параграф: {s['section']}")
        story.append(Paragraph(ptext("; ".join(chapter_bits)), styles["body"]))

        if not claims:
            story.append(Paragraph("В модели пока нет зарегистрированных утверждений этого раздела.", styles["body"]))
            continue

        for claim in claims:
            kind = KIND_RU.get(claim.get("kind"), "утверждение")
            story.append(Paragraph(f"{ptext(claim['id'])} - {ptext(kind)}", styles["h2"]))
            story.append(Paragraph(f"<b>Утверждение.</b> {ptext(claim.get('statement'))}", styles["body"]))

            source = claim.get("source") or {}
            attribution = claim.get("attribution") or {}
            role = ROLE_RU.get(attribution.get("role"), clean_text(attribution.get("role", "не указана")))
            meta = (
                f"Источник: стр. {source.get('page', '?')}, {source.get('locator', 'локатор не указан')}. "
                f"Атрибуция: {attribution.get('name', 'не указана')}, {role}."
            )
            story.append(Paragraph(ptext(meta), styles["small"]))

            deps = claim.get("dependencies") or []
            story.append(Paragraph(
                ptext("Зависимости: " + (", ".join(deps) if deps else "нет зарегистрированных зависимостей")),
                styles["small"],
            ))

            axis_rows = [[
                Paragraph("Ось", styles["small_bold"]),
                Paragraph("Статус", styles["small_bold"]),
                Paragraph("Зафиксированный результат", styles["small_bold"]),
            ]]
            for axis in AXES:
                state = (claim.get("axes") or {}).get(axis) or {}
                axis_rows.append([
                    Paragraph(ptext(AXIS_RU[axis]), styles["small"]),
                    Paragraph(ptext(STATUS_RU.get(state.get("status"), state.get("status", "не задан"))), styles["small"]),
                    Paragraph(ptext(state.get("finding") or "-"), styles["small"]),
                ])
            axis_table = Table(axis_rows, colWidths=[40*mm, 30*mm, 106*mm], repeatRows=1)
            axis_table.setStyle(TableStyle([
                ("GRID", (0, 0), (-1, -1), 0.25, colors.grey),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#F0F0F0")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 3),
                ("TOPPADDING", (0, 0), (-1, -1), 2),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ]))
            story.append(axis_table)
            story.append(Spacer(1, 3 * mm))

            story.append(Paragraph("Матрица Lean 4 / Julia / TypeScript", styles["h3"]))
            vrows = [[Paragraph("Контур", styles["small_bold"]), Paragraph("Состояние", styles["small_bold"])]]
            for track, state in verification_matrix(claim, evidence_by_id):
                vrows.append([Paragraph(ptext(track), styles["small"]), Paragraph(ptext(state), styles["small"])])
            vtable = Table(vrows, colWidths=[35*mm, 141*mm], repeatRows=1)
            vtable.setStyle(TableStyle([
                ("GRID", (0, 0), (-1, -1), 0.25, colors.grey),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#F7F7F7")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 3),
                ("TOPPADDING", (0, 0), (-1, -1), 2),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ]))
            story.append(vtable)

            evidence_ids = []
            for axis in AXES:
                evidence_ids.extend(((claim.get("axes") or {}).get(axis) or {}).get("evidence", []) or [])
            evidence_ids = list(dict.fromkeys(evidence_ids))
            if evidence_ids:
                story.append(Paragraph("Свидетельства", styles["h3"]))
                for eid in evidence_ids:
                    story.append(evidence_summary(eid, evidence_by_id, styles))
            else:
                story.append(Paragraph("Свидетельства для текущих сильных результатов этого утверждения не зарегистрированы.", styles["small"]))
            story.append(Spacer(1, 5 * mm))

    story.append(PageBreak())
    story.append(Paragraph("Принцип интерпретации отчёта", styles["h1"]))
    story.append(Paragraph(
        "Этот PDF является только автоматически формируемой проекцией. Источником научной истины остаётся принятая "
        "машиночитаемая модель и зарегистрированные свидетельства. Ручное редактирование PDF не является способом "
        "изменить научный результат. Если меняется модель, PDF должен быть пересобран.",
        styles["body"],
    ))

    doc.build(story, onFirstPage=page_footer, onLaterPages=page_footer)
    return output.getvalue()


def make_build_record(pdf_bytes: bytes, projection: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema": "repo-guard/projection-build-record/v0",
        "projection_id": projection["id"],
        "model_identity": projection_model_identity(projection),
        "source_identities": [
            {
                "source_id": "book-coverage",
                "algorithm": "sha256",
                "digest": sha256_file(COVERAGE_PATH),
            },
            {
                "source_id": "research-model",
                "algorithm": "sha256",
                "digest": sha256_file(MODEL_PATH),
            },
        ],
        "generator": {
            "contract_id": GENERATOR_CONTRACT,
            "tool_identity": GENERATOR_TOOL_IDENTITY,
        },
        "configuration_digest": configuration_digest(),
        "output_identity": {
            "algorithm": "sha256",
            "digest": sha256_bytes(pdf_bytes),
        },
        "evidence": [
            {"class": "deterministic-generator", "ref": "scripts/generate-audit-report.py"},
            {"class": "repo-guard-projection", "ref": "checks/audit-report-projection.mjs"},
            {"class": "pdf-render-smoke", "ref": ".github/workflows/audit-report.yml"},
        ],
    }


def generate() -> tuple[bytes, bytes]:
    model = json.loads(MODEL_PATH.read_text(encoding="utf-8"))
    coverage = json.loads(COVERAGE_PATH.read_text(encoding="utf-8"))
    projection = json.loads(PROJECTION_PATH.read_text(encoding="utf-8"))
    if projection.get("id") != "pve/sequential-audit-report":
        raise RuntimeError("Неожиданный ID ProjectionModel")
    if projection.get("generator", {}).get("contract_id") != GENERATOR_CONTRACT:
        raise RuntimeError("ProjectionModel ссылается на другой контракт генератора")
    pdf = build_pdf(model, coverage)
    build = make_build_record(pdf, projection)
    return pdf, json_bytes(build)


def main() -> int:
    parser = argparse.ArgumentParser(description="Генератор последовательного русского PDF-аудита")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="сформировать PDF и build record")
    mode.add_argument("--check", action="store_true", help="проверить, что committed output актуален")
    mode.add_argument("--print-config-digest", action="store_true")
    args = parser.parse_args()

    if args.print_config_digest:
        print(configuration_digest())
        return 0

    pdf, build = generate()
    if args.write:
        TARGET_PATH.parent.mkdir(parents=True, exist_ok=True)
        BUILD_PATH.parent.mkdir(parents=True, exist_ok=True)
        TARGET_PATH.write_bytes(pdf)
        BUILD_PATH.write_bytes(build)
        print(f"AUDIT_REPORT_WRITTEN target={TARGET_PATH} sha256={sha256_bytes(pdf)}")
        return 0

    if not TARGET_PATH.is_file() or not BUILD_PATH.is_file():
        print("AUDIT_REPORT_STALE: отсутствует generated PDF или build record", file=sys.stderr)
        return 1
    if TARGET_PATH.read_bytes() != pdf:
        print("AUDIT_REPORT_STALE: PDF не соответствует текущей модели", file=sys.stderr)
        return 1
    if BUILD_PATH.read_bytes() != build:
        print("AUDIT_REPORT_STALE: build record не соответствует текущей модели", file=sys.stderr)
        return 1
    print(f"AUDIT_REPORT_CURRENT sha256={sha256_bytes(pdf)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
