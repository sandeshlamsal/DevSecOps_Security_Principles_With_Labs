# Finding Register

Every weakness found in the lab, rated by **risk in context** ([Principle 01](../docs/principles/01-cia-triad-and-risk.md)),
with the principle it breaks and the lab that fixes it. New findings use the [finding template](../docs/templates/finding.md).

**Status:** Open · Fixed (with evidence) · Accepted (with owner + expiry)

| ID | Found in | Finding | CIA | Risk | Principle | Fixed by | Status |
|---|---|---|---|---|---|---|---|
| F-001 | [Lab 0](../docs/labs/lab-00-foundation.md#step-4-security-posture-baseline) | Pod uses the `default` service account and its API token is auto-mounted | C, I | Medium | [03 Least privilege](../docs/principles/03-least-privilege.md) | Lab 3.1 | Open |
| F-002 | Lab 0 | No container `securityContext`: privilege escalation allowed, capabilities not dropped, root filesystem writable, no seccomp profile | I | Medium | [03 Least privilege](../docs/principles/03-least-privilege.md) | Lab 3.2 | Open |
| F-003 | Lab 0 | No NetworkPolicies: flat pod network, any pod can reach any pod | C, I | Medium | [04 Defence in depth](../docs/principles/04-defense-in-depth.md) | Lab 4.1 | Open |
| F-004 | Lab 0 | Namespace has no Pod Security Admission labels: hardening isn't enforced | I | Medium | [04 Defence in depth](../docs/principles/04-defense-in-depth.md) | Lab 4.2 | Open |
| F-005 | Lab 0 | `/ftp` is a public, unauthenticated directory listing exposing internal documents | C | **High** | [05 Attack surface](../docs/principles/05-attack-surface-reduction.md) | Lab 5.3 | Open |
| F-006 | Lab 0 | `/metrics` served on the public port without authentication | C | Low | [05 Attack surface](../docs/principles/05-attack-surface-reduction.md) | Lab 5.3 | Open |
| F-007 | Lab 0 | `Access-Control-Allow-Origin: *` on API responses | C | Medium | [06 Secure defaults](../docs/principles/06-secure-defaults.md) | Lab 6.1 | Open |
| F-008 | Lab 0 | No `Content-Security-Policy` header (HSTS not applicable: the lab is plain HTTP on localhost) | C, I | Medium | [06 Secure defaults](../docs/principles/06-secure-defaults.md) | Lab 6.1 | Open |
| F-009 | Lab 0 | Image pinned by tag (`v20.2.0`), not by immutable digest | I | Low | [10 Supply chain](../docs/principles/10-supply-chain-integrity.md) | Lab 10.3 | Open |

**Positive observations** (controls already in place, worth recognising in a real report):
- The image runs as a non-root user (UID `65532`).
- The image is distroless: no shell or basic tools (`exec: "ls": executable file not found in $PATH`).
- `X-Content-Type-Options: nosniff` and `X-Frame-Options: SAMEORIGIN` are set.
