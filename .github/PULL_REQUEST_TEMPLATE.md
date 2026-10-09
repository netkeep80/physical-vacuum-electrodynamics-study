## Summary

<!-- What changes and why? Link the owning issue. -->

## ChangeIntent

```repo-guard-yaml
change_type: research
scope:
  - docs/**
budgets: {}
anchors:
  affects: []
  implements: []
  verifies: []
must_touch: []
must_not_touch:
  - repo-policy.json
  - requirements/**
  - .github/workflows/repo-guard.yml
expected_effects:
  - Describe the observable research or infrastructure effect
```

Use canonical requirement IDs such as `PVE-AUD-001` in `anchors.affects/implements/verifies` when applicable.

If a PR intentionally changes governance paths, link the issue that explicitly authorizes that governance change.
