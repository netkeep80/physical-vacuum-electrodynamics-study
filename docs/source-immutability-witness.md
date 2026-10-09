# Source immutability witness [PVE-SRC-001]

The accepted Nikolaev PDF is a protected primary research source.

## Negative witness

Candidate commit `c5b9d600a09c9fbd665051da88318436620c85d4` deleted the protected source file.

With a ChangeIntent that explicitly included the source path, repo-guard produced exactly one
violation:

- rule: `pr-immutable-paths`;
- relation: `paths:pr-immutable:mutation`;
- maximum permitted mutations: 0;
- observed mutations: 1.

The candidate was never merged. The witness branch was reset to the accepted main commit before
this evidence-only document was added.

## Positive witness

This repaired candidate changes only this evidence document. The accepted source PDF remains
byte-identical at the Git blob level to the baseline source object
`ca8052023acbea6c0ec126b135b027c291268d2d` (8,859,035 bytes).

The exact positive candidate SHA and CI result are retained in issue 17.
