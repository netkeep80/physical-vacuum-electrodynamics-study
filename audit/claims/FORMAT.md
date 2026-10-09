# Claim record format [PVE-STATE-001]

This directory contains machine-readable records for substantive claims encountered during the sequential audit.

The format is intentionally small. It is **not** a physics DSL.

A claim JSON uses schema `pve-claim/v1` and contains:

- stable `id`;
- exact `source.page` and `source.locator`;
- optional dependencies/references;
- eight independent status axes:
  - `source_fact`
  - `math`
  - `assumptions`
  - `dimensional`
  - `relation_to_comparator`
  - `invariance`
  - `conservation`
  - `experiment`

Each axis is an object:

```json
{
  "status": "OPEN",
  "evidence": []
}
```

Non-assertive states `OPEN`, `NOT_TESTED`, `GAP`, `NOT_APPLICABLE`, and `CONDITIONAL` may exist without positive evidence.

Assertive states currently recognized by the structural checker — `VERIFIED`, `CONTRADICTED`, `SUPPORTED`, `REJECTED`, `EQUIVALENT`, `NOVEL`, `INCONSISTENT`, `SATISFIED`, `VIOLATED` — require at least one explicit evidence reference.

This only proves structural traceability. It does not prove that cited evidence is scientifically sufficient. Human review and the relevant Lean/Julia/experimental artifacts remain the scientific layer.
