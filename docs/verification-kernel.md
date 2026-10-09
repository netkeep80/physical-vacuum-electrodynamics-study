# Verification kernel

This project separates physical evidence from mathematical verification and requires a **three-track mathematical verification matrix** for every substantive core formula/problem.

## Core applicability

The mandatory gate applies to the core scientific audit beginning at **NIK-0007 / p.81** and to every later mathematical dependency used by the core theory.

For each substantive core mathematical item:

```
claim/formula ID
  -> Lean 4 theorem/check
  -> Julia reproduction
  -> TypeScript numeric regression/property tests
```

A track may be marked N/A only when it is genuinely inapplicable and the reason is explicit. Silent omission is not accepted.

A completed mathematical disposition requires all three tracks to be either evidenced or explicitly justified as N/A.

## Lean 4 — formal implication

Lean 4 is the proof kernel for statements of the form `assumptions -> mathematical consequence`.

Pinned formal baseline:

- Lean: `v4.34.1`;
- Physlib: `e411c6e89692e83bc67fe451302ae7f82cf39b10`;
- that Physlib revision declares Mathlib `v4.34.1` and its manifest resolves Mathlib to `d13f23b723b8a846827a245b89c10fc7d3f11612`.

Accepted project proof code must not use `sorry`/`admit`. CI runs a build plus an axiom audit for the `PVE` namespace.

Lean formalizes exact assumptions, definitions, identities, transformations and implication chains. A Lean PASS proves the formalized statement, not the empirical truth of the physical model.

## Julia — computational reproduction

Julia is the independent symbolic/numeric workbench, pinned in CI to `1.13.1`.

For each applicable formula/problem Julia should reproduce, as appropriate:

- direct numerical evaluation;
- symbolic or algebraic checks;
- limiting cases;
- sensitivity to parameters;
- dimensional/unit-aware checks when justified;
- independent recalculation of examples and tables.

A Julia PASS is computational evidence, not a formal proof and not an empirical measurement.

## TypeScript — numerical regression layer

TypeScript is the continuously executable numerical regression/property layer.

Pinned baseline:

- Node.js: `20`;
- TypeScript: `5.9.3`.

For each applicable formula/problem, TS tests should cover concrete cases such as:

- nominal values;
- zero cases;
- sign reversals;
- boundary/limit cases;
- symmetry/antisymmetry properties;
- selected adversarial values;
- stable expected values or explicit tolerances.

The TS layer is intended to catch implementation regressions and arithmetic/sign mistakes as the audit evolves. It does not replace Lean or Julia.

Baseline files live under `compute/ts/`.

## Physical evidence

Physical claims require observables, comparator predictions where relevant, uncertainty and experiment/literature evidence.

Neither Lean, Julia nor TypeScript alone establishes that a model describes nature.

## Sequential rule

The smoke tests are neutral infrastructure. The first real mandatory core items begin at **NIK-0007 / p.81**.

Later scalar-field cases remain deferred to their proper source position, but when reached their mathematical items must use the same Lean/Julia/TypeScript traceability contract.
