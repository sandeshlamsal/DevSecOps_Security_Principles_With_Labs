# Security Exceptions

Accepting a risk is allowed, but never silently or forever. Every scanner skip in this repo must have a row here with a reason, an owner
and an **expiry date**. `scripts/check-exceptions.py` (part of `make security-scan` and CI) **fails** when:
- an exception is past its expiry date, or
- a `checkov:skip` or `.trivyignore` entry exists without a matching, unexpired row here.

When an exception expires, either fix the issue or renew it **with a new reason** (reviewed in a pull request).

| ID | Scanner rule(s) | Scope | Reason / compensating control | Owner | Expires | Fix planned in |
|---|---|---|---|---|---|---|
| EXC-001 | CKV_AZURE_115, CKV2_AZURE_32 | `infra/azure` AKS + Key Vault | Private cluster / private endpoint need a VPN or bastion (cost, complexity). **Compensating:** API server and Key Vault restricted to an IP allow-list; Key Vault network default Deny | sandesh | 2027-01-18 | Roadmap Phase 2 end: implement, or renew with evidence |
| EXC-002 | CKV_AZURE_117, CKV_AZURE_227 | `infra/azure` AKS | Customer-managed disk encryption and host encryption need extra setup (disk encryption set, subscription feature flag). Platform-managed encryption at rest is on by default | sandesh | 2026-12-14 | Lab AZ-5 (week 11) |
| EXC-003 | CKV_AZURE_4 | `infra/azure` AKS | Azure Monitor log ingestion costs money; logging is turned on with Defender for the detection weeks | sandesh | 2026-12-21 | Labs AZ-6/AZ-7 (weeks 12–13) |
| EXC-006 | KSV-0125 | `apps/juice-shop` deployment | Runs the pinned **upstream** Juice Shop image from Docker Hub (an untrusted registry to Trivy). Deliberate: it's the official image. **Compensating:** digest-pinned; trusted-registry control enforced in Phase 3 via our own GHCR build + Kyverno signature/registry policy | sandesh | 2027-01-31 | Capstone M2–M3 (own signed image) |
| EXC-007 | KSV-0014 | `apps/juice-shop` deployment | `readOnlyRootFilesystem` not set: the app writes into its own served directory (frontend/dist, ftp, logs, uploads, data). Not required by Pod Security `restricted`. **Compensating:** non-root, all caps dropped, no privilege escalation, seccomp RuntimeDefault | sandesh | 2027-03-31 | Scoped `emptyDir` mounts (optional) |
| ~~EXC-005~~ | KSV-* (K8s manifest) | apps/juice-shop | **Closed 2026-09-26**: manifest hardened in [Lab 3](docs/labs/lab-04-least-privilege.md), now passes `trivy config` clean (F-001, F-002, F-009, F-021 fixed) | sandesh | — | done |
| EXC-004 | CKV_AZURE_170, CKV_AZURE_232, CKV_AZURE_226 | `infra/azure` AKS | Cost trade-offs for a lab, not security gaps: paid SLA tier (availability), separate system/user pools, ephemeral OS disks (need a larger VM) | sandesh | 2027-06-30 | Capstone review (Phase 5): document as accepted for a lab |
