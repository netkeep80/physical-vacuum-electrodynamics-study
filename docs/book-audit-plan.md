# Sequential book audit plan [PVE-AUD-001]

Канонический порядок проверки книги Г. В. Николаева «Электродинамика физического вакуума» (2004).

## Progress semantics [PVE-AUD-001]

Базовая единица progress — **раздел книги**.

Статус coverage:

- `NOT_STARTED`;
- `IN_PROGRESS`;
- `PARTIAL`;
- `AUDITED`.

`AUDITED` означает не «согласились с автором», а то, что все существенные классы содержания раздела получили явный disposition, включая `OPEN`, `GAP` или отрицательный результат.

Для каждого раздела по применимости проверяются:

1. точный диапазон источника;
2. нейтральная реконструкция аргумента;
3. корректность **постановки задачи**;
4. определения, постулаты и скрытые предпосылки;
5. логическая зависимость каждого существенного шага от предыдущих;
6. формулы, алгебра, дифференциальные/интегральные и векторные преобразования;
7. начальные и граничные условия;
8. размерности и система единиц;
9. приближения и область применимости;
10. примеры, мысленные эксперименты и численные расчёты;
11. независимое воспроизведение вычислений; при необходимости Julia/Lean;
12. только после этого — физическая интерпретация и отношение к comparator;
13. только после теоретической реконструкции — экспериментальная литература и возможный discriminator;
14. вывод автора: следует ли он из фактически доказанного;
15. незакрытые зависимости.

### Theory-first rule [PVE-MATH-001]

Основной объект критики — **не отличие от mainstream**, а внутреннее качество рассуждения и математического аппарата.

Допустимо расширять или модифицировать Maxwell equations. Такое отличие регистрируется как divergence, но не как ошибка. Ошибка требует конкретного воспроизводимого дефекта внутри постановки, вывода, вычислений или логики.

Comparator analysis и экспериментальная проверка являются downstream-слоями после реконструкции соответствующей теоретической цепочки.

## Context track — front matter, pp. 17–75 [PVE-AUD-001]

Материалы `FRONT` сохраняются в полном coverage, но **не являются блокирующим этапом основного научного аудита**:

1. предисловие к «Непротиворечивой электродинамике»;
2. предисловие к «Современной электродинамике и причинам её парадоксальности»;
3. вместо предисловия к «Электродинамике физического вакуума»;
4. осмысление ситуации в науке и начальные выводы;
5. «От автора»;
6. литература.

Их можно проверять выборочно, когда они дают полезную provenance, исторический контекст или dependency для основного корпуса. Уже принятое evidence не удаляется и не обесценивается. Непроверенный front matter не блокирует переход к физике.

## Core start — Part I, pp. 81–192 [PVE-AUD-001]

Обязательный последовательный научный аудит начинается с **NIK-0007 / стр. 81**.

### Chapter 1
Основные физические свойства среды физического вакуума околоземного пространства, §§1–7.

### Chapter 2
Электромагнитные свойства среды физического вакуума, §§1–10.

Особое внимание: relativity claims, rotating frames, Feynman paradox, Hall effect, Bernoulli analogue, satellite tests.

## Stage 2 — Part II, pp. 197–280 [PVE-AUD-001]

### Chapter 1
Проблемы электростатики пустого пространства, §§1–7.

### Chapter 2
Физический вакуум реального пространства, §§1–7.

### Chapter 3
Вопросы электростатики вакуумной среды, §§1–7.

## Stage 3 — Part III chapters 1–2, pp. 281–326 [PVE-AUD-001]

Последовательно проверить displacement-current construction и радиальное магнитное поле:

- Chapter 1, §§1–6;
- Chapter 2, §§1–5.

Эти главы являются upstream для последующего scalar-field construction.

## Stage 4 — Part III chapters 3–5, pp. 327–416 [PVE-AUD-001]

- Chapter 3: аксиальное/скалярное магнитное поле;
- Chapter 4: заявленное обоснование его физической реальности;
- Chapter 5: система уравнений двух типов магнитного поля.

Deep-dive по (H_{\parallel}=-\operatorname{div}A) активируется только здесь.

## Stage 5 — Part III chapters 6–9, pp. 417–527 [PVE-AUD-001]

- electromagnetic mass and inertia;
- vortex electric fields;
- gradient electric fields;
- energy/work relations.

## Stage 6 — Part III chapters 10–12, pp. 529–609 [PVE-AUD-001]

- accelerated charges and inertia;
- electromagnetic-wave construction;
- transverse/longitudinal waves;
- equations for the complete magnetic field.

## Stage 7 — Part IV, pp. 611–694 [PVE-AUD-001]

Последовательно проверить все 20 концептуальных разделов, включая:

- foundations;
- charge and inertia;
- gravity;
- vacuum structure;
- kinematics;
- reinterpretation of relativity/optics;
- paradoxes;
- experimental claims for scalar magnetic field;
- equivalence principle;
- annihilation;
- curvature;
- wave-particle duality;
- torsion fields;
- claimed dead ends;
- final field equations;
- conclusion and literature.

## Dependency rule [PVE-MATH-001, PVE-PHY-001]

Если поздняя формула зависит от раннего `OPEN/GAP`:

- математическое следствие может быть проверено условно;
- dependency edge сохраняется;
- физический статус не повышается как будто premise доказан.

Последовательный аудит продолжается, но долг не скрывается.

## Completion condition [PVE-STATE-001]

Основной научный аудит считается завершённым, когда **каждый substantive section Parts I–IV** имеет coverage `AUDITED` и все вынесенные deep-dive dependencies имеют явный конечный или OPEN/GAP status.

`FRONT` остаётся отдельным contextual track: его coverage сохраняется, но полная аудированность pp. 17–75 не является условием завершения core scientific audit.
