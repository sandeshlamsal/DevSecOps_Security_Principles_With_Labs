# DevSecOps & Security Engineering: Principles, Interviews & Labs

[![security](https://github.com/sandeshlamsal/DevSecOps_Security_Principles_With_Labs/actions/workflows/security.yml/badge.svg)](https://github.com/sandeshlamsal/DevSecOps_Security_Principles_With_Labs/actions/workflows/security.yml)
[![ci](https://github.com/sandeshlamsal/DevSecOps_Security_Principles_With_Labs/actions/workflows/ci.yml/badge.svg)](https://github.com/sandeshlamsal/DevSecOps_Security_Principles_With_Labs/actions/workflows/ci.yml)

A hands-on lab that prepares you for **Security Engineer, DevSecOps Engineer and Application Security (AppSec) roles**.
You run a real, intentionally insecure web app on your own laptop, then **find, fix, prevent and detect** its weaknesses
the way a production security team would: threat models, secure code review, pipeline security gates, supply-chain
controls, container and Kubernetes hardening, runtime detection and incident response.

**Lab app:** [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/), the OWASP flagship training app. It covers the
OWASP Top 10 and more, and is meant to be run locally for learning. The reasons for this choice are in
[ADR-0001](docs/adr/0001-lab-application.md).

> **Ground rule:** only test systems you own or are explicitly authorised to test. Everything here runs on
> `127.0.0.1` in a local kind cluster. See [security-way.md](docs/security-way.md).

## Where to start

⭐ **[What this lab proves](docs/security-in-practice.md)**: principle → build → evidence → lesson (start here if you're hiring or interviewing).

🗺️ **[INDEX.md](INDEX.md)**: the map of every page and file in the project.


| You are… | Start with |
|---|---|
| **New to security** | 👶 [Baby steps](docs/basics/README.md): eight short, plain-English lessons, each with a small hands-on exercise |
| **Moving from DevOps into security** | 🧭 [Career pathways](docs/career/PATHWAYS.md): DevSecOps, Cloud Security, AppSec, Detection & Response, GRC: plans per role |
| **Targeting a job** | 🎯 [Career guide](docs/career/README.md): what each role does, the skills map, and how this lab proves each skill |
| **Ready to build** | 🧪 [Labs](docs/labs/README.md): step-by-step guides with real commands, output and issues |
| **Following a plan** | 🗺️ [Roadmap](docs/career/ROADMAP.md): 36 weeks, 5 phases (fundamentals → Azure cloud security → DevSecOps pipeline → Kubernetes security → portfolio), with certifications |
| **Hiring / reviewing** | 🏗️ [Capstone](docs/capstone/README.md): a GitOps pipeline hardened end to end, with blocking security gates and expiring exceptions |
| **Learning the principles** | 📐 [Principles](docs/principles/README.md): 13 principles, each with its own hands-on labs |
| **Looking up a term or tool** | 📖 [Glossary](docs/GLOSSARY.md): SAST, DAST, SBOM, SOPS, Checkov and 150+ more, each with where it's used in this lab |
| **Seeing how the tools connect** | 🔧 [DevSecOps toolchain](docs/architecture/devsecops-toolchain.md): pipeline diagram, SAST/DAST/SCA, vulnerability reporting flow |
| **Hardening Linux hosts** | 🐧 [Linux security notes](docs/linux-security/README.md): firewalls, reverse proxies, ACLs, SELinux/AppArmor, auditd, built-in analysis tools |
| **Audits, standards and compliance** | 📋 [GRC](docs/grc/README.md): audits, ISO 27001, SOC 2, FedRAMP, GDPR/NIS2/DORA, PII, PCI DSS, ATM and EDI security, phishing simulations |
| **Working with cloud and Kubernetes** | ☁️ [Securing the stack](docs/architecture/README.md): cloud, cluster, containers, pods and microservices, layer by layer |

## Security gates on this repo

Every push and PR runs [six blocking security gates](scripts/security-scan.sh): secrets (gitleaks), CI supply chain (Semgrep),
Kubernetes misconfiguration (Trivy), Terraform (Checkov), an **exceptions register where every accepted risk expires**
([SECURITY-EXCEPTIONS.md](SECURITY-EXCEPTIONS.md)), and Kyverno admission policies. A second job uploads every scanner's results as
SARIF to the repo's **Security → Code scanning** tab, and runs weekly so new CVEs surface without a push. Run the gates locally with `make security-scan`.
How it all fits: [toolchain diagram](docs/architecture/devsecops-toolchain.md).

## Quick start

Prerequisites: Docker (4 CPUs, 6 GB RAM is plenty), kind, kubectl.

```bash
make cluster-up   # 3-node kind cluster (~1 min)
make deploy       # OWASP Juice Shop (~30 s)
make status
make open         # http://localhost:3000 (bound to 127.0.0.1 only)
```

## Progress: principles and their labs

| # | Principle | Role skill it proves | Status |
|---|---|---|---|
| 00 | [Lab foundation & security baseline](docs/labs/lab-00-foundation.md) | Assess an unfamiliar system | ✅ baseline |
| 01 | [CIA triad & risk](docs/principles/01-cia-triad-and-risk.md) | Risk-based prioritisation | ✅ 17 assets rated |
| 02 | [Threat modelling](docs/principles/02-threat-modeling.md) | Design review (STRIDE) | ✅ 21 threats |
| 03 | [Least privilege](docs/principles/03-least-privilege.md) | K8s/cloud identity hardening | ✅ pod hardened |
| 04 | [Defence in depth](docs/principles/04-defense-in-depth.md) | NetworkPolicy, Pod Security | 🟡 netpol + PSS |
| 05 | [Minimise attack surface](docs/principles/05-attack-surface-reduction.md) | Exposure management | 🟡 5.1, 5.3 done |
| 06 | [Secure defaults](docs/principles/06-secure-defaults.md) | Headers, CSP, error handling | ✅ headers, errors |
| 07 | [Never trust input](docs/principles/07-never-trust-input.md) | SAST triage, secure code fixes | 🟡 SAST + custom rule |
| 08 | [Identity & access](docs/principles/08-identity-and-access.md) | AuthN/AuthZ review | ⏳ |
| 09 | [Protect data & secrets](docs/principles/09-protect-data-and-secrets.md) | Secret scanning, leak response | ⏳ |
| 10 | [Supply-chain integrity](docs/principles/10-supply-chain-integrity.md) | SBOM, CVE triage, signing | ⏳ |
| 11 | [Shift left](docs/principles/11-shift-left-automation.md) | DevSecOps pipeline gates | ✅ gates+hooks+exceptions |
| 12 | [Assume breach](docs/principles/12-assume-breach.md) | Detection, incident response | 🟡 Falco live |
| 13 | [Security in the AI era](docs/principles/13-ai-era-security.md) | LLM app security, AI-driven threats | ✅ review+tests+process |

**Security audit:** 24 issues found so far (1 Critical, 8 High). See the [remediation plan](findings/REMEDIATION.md) for every issue, its fix, how to verify it, and the CI gate that keeps it fixed. Status per issue: [finding register](findings/README.md).

## Repository layout

| Path | Purpose |
|---|---|
| [docs/basics/](docs/basics/README.md) | **Baby steps**: fundamentals for beginners, one concept per page |
| [docs/career/](docs/career/README.md) | Roles, skills map, certifications, interview preparation |
| [docs/principles/](docs/principles/README.md) | Security engineering principles mapped to this lab |
| [docs/labs/](docs/labs/README.md) | **Lab status and step-by-step execution guides** |
| [docs/security-in-practice.md](docs/security-in-practice.md) | **What this lab proves**: principle → build → evidence → lesson |
| [docs/career/ROADMAP.md](docs/career/ROADMAP.md) | 36-week roadmap to DevSecOps / Cloud Security roles |
| [docs/capstone/](docs/capstone/README.md) | Portfolio project: hardened GitOps pipeline (design, decisions, milestones) |
| [docs/cloud/](docs/cloud/README.md) · [infra/azure/](infra/azure/) | Azure cloud security labs + secure-by-default AKS Terraform |
| [docs/architecture/](docs/architecture/README.md) | Securing cloud, Kubernetes, containers, pods and microservices · [toolchain](docs/architecture/devsecops-toolchain.md) |
| [docs/GLOSSARY.md](docs/GLOSSARY.md) | Security terms and tools, A–Z |
| [docs/linux-security/](docs/linux-security/README.md) | Linux security notes |
| [docs/grc/](docs/grc/README.md) | Governance, risk and compliance: audits, standards, privacy, payments |
| [docs/career/PATHWAYS.md](docs/career/PATHWAYS.md) | DevOps → security role pathways |
| [docs/security-way.md](docs/security-way.md) | Our operating rules (ethics, secrets, evidence) |
| [docs/adr/](docs/adr/) | Architecture Decision Records |
| [docs/templates/](docs/templates/) | Threat model, finding and security-incident templates |
| [findings/](findings/README.md) | Finding register + [security audit & remediation plan](findings/REMEDIATION.md) |
| [threat-models/](threat-models/README.md) | Threat models (Phase 1 onward) |
| [apps/juice-shop/](apps/juice-shop/) | The app's Kubernetes manifest, hardened lab by lab |
| [platform/](platform/) | Cluster config, [Kyverno policies](platform/kyverno/) |
| [gitops/](gitops/) | Argo CD applications |
| [SECURITY-EXCEPTIONS.md](SECURITY-EXCEPTIONS.md) | Accepted risks, each with a reason, owner and expiry (enforced by CI) |
