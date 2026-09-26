# Finding Register

> **Full audit with fixes:** [REMEDIATION.md](REMEDIATION.md): every issue, why it matters, the fix, how to verify it, and the CI gate that keeps it fixed.

Every weakness found in the lab, rated by **risk in context** ([Principle 01](../docs/principles/01-cia-triad-and-risk.md)),
with the principle it breaks and the lab that fixes it. New findings use the [finding template](../docs/templates/finding.md).

**Status:** Open · Fixed (with evidence) · Accepted (with owner + expiry)

| ID | Found in | Finding | CIA | Risk | Principle | Fixed by | Status |
|---|---|---|---|---|---|---|---|
| F-001 | [Lab 0](../docs/labs/lab-00-foundation.md#step-4-security-posture-baseline) | Pod uses the `default` service account and its API token is auto-mounted | C, I | Medium | [03 Least privilege](../docs/principles/03-least-privilege.md) | Lab 3.1 | Open |
| F-002 | Lab 0 | No container `securityContext`: privilege escalation allowed, capabilities not dropped, root filesystem writable, no seccomp profile | I | Medium | [03 Least privilege](../docs/principles/03-least-privilege.md) | Lab 3.2 | Open |
| F-003 | Lab 0 | No NetworkPolicies: flat pod network, any pod can reach any pod | C, I | Medium | [04 Defence in depth](../docs/principles/04-defense-in-depth.md) | Lab 4.1 | Open |
| F-004 | Lab 0 | Namespace has no Pod Security Admission labels: hardening isn't enforced | I | Medium | [04 Defence in depth](../docs/principles/04-defense-in-depth.md) | Lab 4.2 | Open |
| F-005 | Lab 0 | `/ftp` is a public, unauthenticated directory listing exposing internal documents (Lab 1.1 source review: includes a password-manager database `incident-support.kdbx` and `.bak` backup files) | C | **High** | [05 Attack surface](../docs/principles/05-attack-surface-reduction.md) | Lab 5.3 | Open |
| F-006 | Lab 0 | `/metrics` served on the public port without authentication | C | Low | [05 Attack surface](../docs/principles/05-attack-surface-reduction.md) | Lab 5.3 | Open |
| F-007 | Lab 0 | `Access-Control-Allow-Origin: *` on API responses | C | Medium | [06 Secure defaults](../docs/principles/06-secure-defaults.md) | Lab 6.1 | Open |
| F-008 | Lab 0 | No `Content-Security-Policy` header (HSTS not applicable: the lab is plain HTTP on localhost) | C, I | Medium | [06 Secure defaults](../docs/principles/06-secure-defaults.md) | Lab 6.1 | Open |
| F-009 | Lab 0 | Image pinned by tag (`v20.2.0`), not by immutable digest | I | Low | [10 Supply chain](../docs/principles/10-supply-chain-integrity.md) | Lab 10.3 | Open |
| F-010 | [Lab 1.1](../docs/labs/lab-01-cia-and-risk.md) | JWT **signing private key hard-coded** in source (`lib/insecurity.ts:21`); the source is public, so anyone can create valid sessions for any user | C, I | **High** | [09 Secrets](../docs/principles/09-protect-data-and-secrets.md), [08 Identity](../docs/principles/08-identity-and-access.md) | Lab 9.x (load key from a Secret, rotate) | Open |
| F-011 | Lab 1.1 | Passwords hashed with **unsalted MD5** (`lib/insecurity.ts:41`); fast to crack if the database leaks | C | **High** | [08 Identity](../docs/principles/08-identity-and-access.md) | Lab 8.3 | Open |
| F-012 | Lab 1.1 | Database is a SQLite file inside the container with no volume and no backup; a pod restart **erased all new data** (a newly registered customer could no longer log in) | I, A | Medium | [01 CIA](../docs/principles/01-cia-triad-and-risk.md), [12 Recover](../docs/principles/12-assume-breach.md) | Lab 12.x (backup/restore), optional | Open (by design for a training app; would be High in production) |
| F-013 | [Security audit](REMEDIATION.md) | **Infrastructure code publicly served** at `/infrastructure` (Terraform, Dockerfile, docker-compose), including a Terraform file that **contains a private key** (`networking.tf` → HTTP 200) | C | **Critical** | [05](../docs/principles/05-attack-surface-reduction.md), [09](../docs/principles/09-protect-data-and-secrets.md) | Plan step B1, C1 | Open |
| F-014 | Security audit | Server **access logs** publicly listed and downloadable at `/support/logs` | C | **High** | [05](../docs/principles/05-attack-surface-reduction.md), [12](../docs/principles/12-assume-breach.md) | B1, C1 | Open |
| F-015 | Security audit | `/encryptionkeys` lists a **secret key** (`premium.key`) publicly (the `jwt.pub` public key there is fine) | C, I | **High** | [09](../docs/principles/09-protect-data-and-secrets.md) | B1, C1 | Open |
| F-016 | Security audit (Semgrep, confirmed by reading code) | **SQL injection**: request data pasted into SQL strings in `routes/login.ts:34` (email) and `routes/search.ts:23` (search term) | C, I | **High** | [07](../docs/principles/07-never-trust-input.md) | Lab 7.2 | Open |
| F-017 | Security audit (Trivy) | **53 High/Critical CVEs** in the image (8 Critical, 45 High); 52 in Node.js packages, 1 in OpenSSL; **51 have a fixed version** | C, I, A | **High** | [10](../docs/principles/10-supply-chain-integrity.md) | Lab 10.2 | Open |
| F-018 | Security audit (Semgrep) | File-serving routes build paths from request data (CWE-73): `fileServer.ts:32`, `keyServer.ts:14`, `logfileServer.ts:14`, `quarantineServer.ts:14` | C | Medium | [07](../docs/principles/07-never-trust-input.md) | Lab 7.1 | Needs triage |
| F-019 | Security audit (Semgrep) | Possible **code injection** (CWE-95) in `routes/userProfile.ts:65` | C, I, A | High (if confirmed) | [07](../docs/principles/07-never-trust-input.md) | Lab 7.1 | Needs triage |
| F-020 | Security audit (Semgrep) | Possible **open redirect** (CWE-601) in `routes/redirect.ts:18` | I | Medium | [07](../docs/principles/07-never-trust-input.md) | Lab 7.1 | Needs triage |
| F-021 | Security audit (Trivy config) | No CPU limit; image registry not restricted to trusted sources (KSV-0011, KSV-0125) | A, I | Low | [03](../docs/principles/03-least-privilege.md), [10](../docs/principles/10-supply-chain-integrity.md) | A1, Lab 10.3 | Open |
| F-022 | Security audit | `/.well-known` has a directory listing (its files are meant to be public; the listing isn't needed) | C | Low | [05](../docs/principles/05-attack-surface-reduction.md) | C1 | Open |
| F-023 | Security audit (Semgrep on **our** repo) | Our CI used a mutable action tag (`actions/checkout@v4`); a moved tag could run different code with our CI permissions | I | Low | [10](../docs/principles/10-supply-chain-integrity.md), [11](../docs/principles/11-shift-left-automation.md) | Pinned to SHA `11bd719…` (v4.2.2) | **Fixed** 2026-09-26 (`semgrep --config p/github-actions .github/` → 0 findings) |
| F-024 | Security audit (Semgrep) | npm configured without a minimum release age (`.npmrc`, `frontend/.npmrc`): brand-new, possibly malicious package versions install immediately | I | Low | [10](../docs/principles/10-supply-chain-integrity.md), [13](../docs/principles/13-ai-era-security.md) | Plan step C5 | Open |
| F-025 | [Lab 2](../docs/labs/lab-02-threat-modeling.md) (threat model) | OAuth login derives the account password from the user's email by a reversible, client-side transform (`frontend/.../oauth.component.ts`), so an email is effectively the password | C, I | **High** | [08 Identity](../docs/principles/08-identity-and-access.md) | Lab 8.x | Open |
| F-026 | Lab 2 | `/rest/user/change-password` takes the password in the **URL query string** (GET); it is written in clear to the access log (`morgan combined`), which is also publicly served (F-014) | C | **High** | [09 Secrets](../docs/principles/09-protect-data-and-secrets.md), [06 Secure defaults](../docs/principles/06-secure-defaults.md) | Lab 6.x / C-series | Open (verified on own test account) |
| F-027 | Lab 2 | `/profile/image/url` makes the server `fetch()` an attacker-supplied URL (**SSRF**); can reach internal services or cloud metadata | C | **High** | [07 Never trust input](../docs/principles/07-never-trust-input.md) | Lab 7.x (allow-list, block internal ranges) | Open |
| F-028 | Lab 2 | `/b2b/v2/orders` passes request data to a JavaScript `eval` inside a `vm` sandbox (`b2bOrder.ts`); sandbox escape → code execution | C, I, A | **High** | [07 Never trust input](../docs/principles/07-never-trust-input.md) | Lab 7.x (remove eval, patch deps) | Open |
| F-029 | Lab 2 | XML upload parses with entity expansion enabled (`XML_PARSE_NOENT`, `XML_PARSE_DTDLOAD` in `lib/xml.ts`): **XXE** (file read, SSRF) and billion-laughs DoS | C, A | **High** | [07 Never trust input](../docs/principles/07-never-trust-input.md) | Lab 7.x (disable entity/DTD loading) | Open |

**Positive observations** (controls already in place, worth recognising in a real report):
- The image runs as a non-root user (UID `65532`).
- The image is distroless: no shell or basic tools (`exec: "ls": executable file not found in $PATH`).
- `X-Content-Type-Options: nosniff` and `X-Frame-Options: SAMEORIGIN` are set.
