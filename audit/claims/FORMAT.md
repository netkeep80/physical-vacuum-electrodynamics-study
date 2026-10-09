# Research model format [PVE-STATE-001]

Scientific claim state is stored canonically in [`audit/research-model.json`](../research-model.json).

This directory is retained as the historical location of the pre-audit `pve-claim/v1` sketch. No scientific claim JSON was accepted under that sketch, so the project moved to the single canonical `pve-research-model/v1` before page-17 auditing began.

The canonical model contains:

- `evidence[]` — stable `EVID-000001` style evidence objects with typed locators;
- `claims[]` — stable `NIK-0001-C001` style claims;
- exact `section_id`, `source.page` and `source.locator`;
- eight independent status axes;
- `finding` plus evidence IDs for every strong axis status;
- explicit claim dependencies.

The generated publication is [`docs/generated/verified-facts.md`](../../docs/generated/verified-facts.md). It is not edited manually and is not an independent source of truth.
