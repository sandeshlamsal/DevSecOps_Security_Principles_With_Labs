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
| EXC-004 | CKV_AZURE_170, CKV_AZURE_232, CKV_AZURE_226 | `infra/azure` AKS | Cost trade-offs for a lab, not security gaps: paid SLA tier (availability), separate system/user pools, ephemeral OS disks (need a larger VM) | sandesh | 2027-06-30 | Capstone review (Phase 5): document as accepted for a lab |
| EXC-005 | KSV-0001, 0003, 0004, 0011, 0012, 0014, 0020, 0021, 0030, 0104, 0106, 0118, 0125 | `apps/juice-shop/juice-shop.yaml` | The deliberately unhardened Lab 0 "before" manifest (findings F-001, F-002, F-004, F-009, F-021). **Compensating:** app reachable on 127.0.0.1 only | sandesh | 2027-03-29 | Plan step A1 (roadmap week 27) |
