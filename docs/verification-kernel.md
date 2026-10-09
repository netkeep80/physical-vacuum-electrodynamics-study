# Verification kernel

This project deliberately separates three kinds of evidence.

## Formal implication

Lean 4 is the proof kernel for statements of the form `assumptions -> mathematical consequence`.
The infrastructure baseline imports a pinned Physlib revision; it does not assert empirical truth.

Pinned formal baseline:

- Lean: `v4.34.1`;
- Physlib: `e411c6e89692e83bc67fe451302ae7f82cf39b10`;
- that Physlib revision declares Mathlib `v4.34.1` and its manifest resolves Mathlib to `d13f23b723b8a846827a245b89c10fc7d3f11612`.

Accepted project proof code must not use `sorry`/`admit`. CI runs a build plus an axiom audit for the `PVE` namespace.

## Computational evidence

Julia is the symbolic/numeric workbench, initially pinned in CI to `1.13.1`.
A numerical/symbolic result is reproducible computational evidence, not a formal proof and not an empirical measurement.

Packages such as Symbolics, ModelingToolkit and unit systems are intentionally not added until a real sequential audit case requires them.

## Physical evidence

Physical claims require observables, comparator predictions, uncertainty and experiment/literature evidence.
Neither a Lean theorem nor a Julia calculation alone establishes that a model describes nature.

## Sequential rule

The smoke tests are neutral infrastructure. The first real Nikolaev claim enters this pipeline only when encountered by the page-ordered audit beginning at page 17.
The later `H_parallel` case remains deferred to its proper place in Part III.
