# Labs: Organised by Principle

Every lab belongs to a [principle](../principles/README.md). The **lab plan** (steps) lives on the principle page; when a lab is
executed, its **execution guide** (the real commands, output and issues) is added here as `lab-NN-*.md`.

## Status

| Principle | Labs | Execution guide | Status |
|---|---|---|---|
| 00 Foundation | 0 | [lab-00-foundation.md](lab-00-foundation.md) | ✅ 2026-09-26 · 9 findings, 3 issues |
| [01 CIA triad & risk](../principles/01-cia-triad-and-risk.md) | 1.1 assets · 1.2 risk-rating | [lab-01-cia-and-risk.md](lab-01-cia-and-risk.md) | ✅ 2026-09-26 · 3 new findings, 2 issues |
| [02 Threat modelling](../principles/02-threat-modeling.md) | 2.1 DFD · 2.2 STRIDE · 2.3 change model | [lab-02-threat-modeling.md](lab-02-threat-modeling.md) | ✅ 2026-09-26 · 21 threats, 5 new findings |
| [03 Least privilege](../principles/03-least-privilege.md) | 3.1 SA token · 3.2 securityContext · 3.3 RBAC | [lab-04-least-privilege.md](lab-04-least-privilege.md) | ✅ 2026-09-26 · F-001/002/009/021 fixed |
| [04 Defence in depth](../principles/04-defense-in-depth.md) | 4.1 NetworkPolicy · 4.2 Pod Security · 4.3 layer map | [lab-05-defense-in-depth.md](lab-05-defense-in-depth.md) | 🟡 4.1 ✅ · 4.2 ✅ · 4.3 ⏳ |
| [05 Attack surface](../principles/05-attack-surface-reduction.md) | 5.1 enumerate · 5.2 image surface · 5.3 close doors | [lab-03-attack-surface-and-defaults.md](lab-03-attack-surface-and-defaults.md) | 🟡 5.1 ✅ · 5.2–5.3 ⏳ |
| [06 Secure defaults](../principles/06-secure-defaults.md) | 6.1 headers/CSP · 6.2 error handling | [lab-03-attack-surface-and-defaults.md](lab-03-attack-surface-and-defaults.md) | ✅ 2026-09-26 · 2 new findings |
| [07 Never trust input](../principles/07-never-trust-input.md) | 7.1 SAST · 7.2 fix · 7.3 custom rule | — | ⏳ |
| [08 Identity & access](../principles/08-identity-and-access.md) | 8.1 session · 8.2 authz review · 8.3 password storage | — | ⏳ |
| [09 Data & secrets](../principles/09-protect-data-and-secrets.md) | 9.1 secret scan · 9.2 K8s Secrets · 9.3 leak response | — | ⏳ |
| [10 Supply chain](../principles/10-supply-chain-integrity.md) | 10.1 SBOM · 10.2 CVE triage · 10.3 sign + verify | — | ⏳ |
| [11 Shift left](../principles/11-shift-left-automation.md) | 11.1 CI gates · 11.2 pre-commit · 11.3 baselines | — | ⏳ |
| [12 Assume breach](../principles/12-assume-breach.md) | 12.1 Falco · 12.2 audit logs · 12.3 game day | — | ⏳ |
| [13 AI-era security](../principles/13-ai-era-security.md) | 13.1–13.5 | — | ⏳ |

## Conventions
- **Issue IDs:** `ISSUE-n` in Lab 0, then `L3-ISSUE-n` for Principle 3's labs, and so on. Each has a symptom, root cause, fix and verification.
- **Finding IDs:** `F-n`, recorded in the [finding register](../../findings/README.md).
- **Times are UTC.**
- **Scope:** only the local kind cluster. The app is reachable on `127.0.0.1` only ([security-way.md](../security-way.md)).
- **Secrets never go in Git.** Scanner reports go to `reports/` (git-ignored); curated results go into findings.
