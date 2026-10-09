# Physical Vacuum Electrodynamics Study

Независимое воспроизводимое исследование книги Г. В. Николаева «Электродинамика физического вакуума» (2004).

## Текущее состояние

Исследовательская инфраструктура собрана и работает. Контекстные материалы pp. 17–32 уже дали полезные provenance/evidence, но **основной научный аудит теории начинается с Части I, стр. 81 (`NIK-0007`)**.

Уже приняты:

- исследовательский протокол и исполняемые требования;
- repo-guard и research-integrity CI;
- защита исходного PDF и точная фиксация корпуса;
- полный coverage из 139 разделов;
- каноническая research model + generated verified-facts projection;
- Lean 4 + Physlib verification kernel;
- Julia computational workbench;
- базовая гигиена веток, PR и issues;
- repo-local ANet bootstrap.

Front matter pp. 17–75 сохраняется как **context track**: его можно проверять выборочно, но он не блокирует движение по физике. Обязательный **core track** идёт последовательно по Parts I–IV, начиная со стр. 81.

## Основные правила

- GitHub accepted `main` — единственный source of truth проекта. [PVE-GOV-001]
- Исходный PDF — защищённый первичный объект исследования. [PVE-SRC-001]
- Core-аудит идёт по основному корпусу последовательно, начиная с Part I / p.81. [PVE-AUD-001]
- Front matter хранится как non-blocking contextual corpus. [PVE-AUD-001]
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
