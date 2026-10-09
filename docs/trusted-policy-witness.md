# Trusted policy self-relaxation witness [PVE-GOV-001]

A candidate pull request must not be able to authorize itself by weakening the policy used to judge
that same transition.

## Negative witness

Candidate `834c5835a474bce35a6bd7c16e96c363ea476e6c` used a syntactically valid candidate policy
with the accepted immutable-source boundary removed.

The accepted BASE still rejected the transition:

- `pr-immutable-policy-set` detected that the accepted immutable set was absent from HEAD;
- `governance-change-authorization` rejected the unauthorized `repo-policy.json` mutation.

The linked issue intentionally provided no GovernanceGrant.

## Repair

The candidate policy was then restored exactly to the accepted `main` policy. Only this evidence
document remains in the final diff. Exact CI results are retained in issue 19.
