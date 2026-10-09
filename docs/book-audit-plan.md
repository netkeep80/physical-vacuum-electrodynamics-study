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
3. определения и предпосылки;
4. исторические/фактические утверждения;
5. формулы и зависимости;
6. размерности и система единиц;
7. примеры и мысленные эксперименты;
8. численные результаты;
9. сравнение с comparator на той же постановке;
10. экспериментальная литература;
11. вывод автора;
12. независимые status axes;
13. незакрытые зависимости.

## Stage 0 — introductory corpus, pp. 17–75 [PVE-AUD-001]

Последовательно:

1. предисловие к «Непротиворечивой электродинамике»;
2. предисловие к «Современной электродинамике и причинам её парадоксальности»;
3. вместо предисловия к «Электродинамике физического вакуума»;
4. осмысление ситуации в науке и начальные выводы;
5. «От автора»;
6. литература.

Задача этапа — зафиксировать исходные premises, исторические claims, объявленные парадоксы и методологию **до** проверки поздней математики.

## Stage 1 — Part I, pp. 81–192 [PVE-AUD-001]

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

## Dependency rule [PVE-PHY-001]

Если поздняя формула зависит от раннего `OPEN/GAP`:

- математическое следствие может быть проверено условно;
- dependency edge сохраняется;
- физический статус не повышается как будто premise доказан.

Последовательный аудит продолжается, но долг не скрывается.

## Completion condition [PVE-STATE-001]

Книга считается полностью аудированной только когда **каждый substantive section** имеет coverage `AUDITED` и все вынесенные deep-dive dependencies имеют явный конечный или OPEN/GAP status.
