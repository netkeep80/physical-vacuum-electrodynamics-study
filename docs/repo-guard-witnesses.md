# repo-guard trusted-base witnesses [PVE-GOV-001]

This retained record documents the first trusted-base requirement-resolution witness after the
initial repository bootstrap.

## Negative witness

Candidate SHA:

`1fc0071e733a760e71560507e60aba9db83d33e7`

The candidate used the syntactically valid but nonexistent requirement id a syntactically valid but nonexistent GOV requirement identifier.

Observed repo-guard result:

- `result: failed`;
- exactly one violation;
- rule: `trace-rule: doc-req-refs-must-resolve`;
- missing value: a syntactically valid but nonexistent GOV requirement identifier.

This is the intended falsifier: a requirement-shaped reference cannot silently resolve to nothing.

## Positive witness

The candidate is now corrected to the real requirement `PVE-GOV-001`.

The exact GREEN candidate SHA and run result are recorded in the owning witness issue after CI
completes, so this file does not need a self-referential commit hash update.
