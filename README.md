# Physical Vacuum Electrodynamics Study

Независимое воспроизводимое исследование книги Г. В. Николаева «Электродинамика физического вакуума» (2004).

## Текущее состояние

Научный аудит книги **ещё не начат**. Базовая исследовательская инфраструктура уже собрана и проверяется перед переходом к странице 17.

Уже приняты:

- исследовательский протокол и исполняемые требования;
- repo-guard и research-integrity CI;
- защита исходного PDF и точная фиксация корпуса;
- полный последовательный coverage из 139 разделов;
- Lean 4 + Physlib verification kernel;
- Julia computational workbench;
- базовая гигиена веток, PR и issues;
- repo-local ANet bootstrap.

Перед стартом научного аудита остаётся закрыть последние инфраструктурные acceptance-witnesses, не меняя научный статус книги.

После этого исследование начинается с первых страниц книги и идёт последовательно до конца.

## Основные правила

- GitHub accepted `main` — единственный source of truth проекта. [PVE-GOV-001]
- Исходный PDF — защищённый первичный объект исследования. [PVE-SRC-001]
- Аудит идёт по книге последовательно, а не выборочно по интересным гипотезам. [PVE-AUD-001]
- Корректность математики и истинность физической интерпретации — разные вопросы. [PVE-PHY-001]
- Сильный научный статус требует воспроизводимого evidence. [PVE-STATE-001]
- Ветки, PR и issues должны оставаться трассируемыми; неоднозначная уникальная работа не удаляется автоматически. [PVE-HYG-001]

## Навигация

- Roadmap: #1
- Infrastructure: #2
- ANet: #3
- Corpus: #4
- Verification kernel: #5
- Executable requirements: #10
- Sequential book audit plan: #11
- ANet memory root: #12
- Repository hygiene: #14

Канонические процедуры: [research protocol](docs/research-protocol.md), [book audit plan](docs/book-audit-plan.md), [verification kernel](docs/verification-kernel.md) и [repository hygiene](docs/repository-hygiene.md).
