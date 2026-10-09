# Repository hygiene [PVE-HYG-001]

## Purpose

The book audit may run for a long time and create many research branches, pull requests and issues. Repository hygiene must reduce accidental hidden work and backlog entropy without deleting ambiguous scientific work.

## Branches

A side branch with unique commits should be represented by an open draft PR.

The branch-hygiene workflow may automatically delete a branch only when a safe proof exists:

1. the current head exactly equals the head snapshot of a merged same-repository PR;
2. the branch is zero commits ahead of the default branch; or
3. its patch is proven equivalent and the branch has closed-PR provenance.

The workflow must keep:

- the default branch;
- protected branches;
- branches backing open PRs;
- branches with unclassified unique commits;
- patch-equivalent branches without closed-PR provenance.

Deletion is intentionally conservative.

## Pull requests

Every open PR should point to at least one owning or related issue.

A generated draft PR is only a visibility placeholder. Before becoming ready it must have:

- task-specific title;
- task-specific body;
- relevant ChangeIntent;
- issue relation;
- acceptance/evidence description appropriate to the task.

Duplicate open PRs for the same head are hygiene defects.

PR inactivity is reported, not automatically closed.

## Issues

The roadmap (#1) and ANet memory root (#12) are intentional roots. Ordinary work items should identify a parent.

New UI-created issues use the structured task form and should state:

- work class;
- parent;
- goal;
- scope;
- dependencies;
- acceptance criteria.

Research issues are never auto-closed solely because they are old. A stale issue may still represent an unresolved scientific dependency.

## Enforcement stages

Current bootstrap:

- branch safety automation: active;
- PR/issue structure audit: advisory/report-only;
- repo-guard: advisory.

After positive and negative witnesses, specific unambiguous rules may move to blocking. Destructive automation must remain limited to branches with safe deletion proofs.
