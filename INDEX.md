# Project Index: Every Page and File

The map of the whole repo. Every document and every code/config file is listed here with one line saying what it's for.
CI checks that **every Markdown page is linked from this index**, so nothing gets lost ([check-links.py](scripts/check-links.py)).

← [README](README.md) (overview + quick start)

## Contents
1. [Start here](#1-start-here)
2. [Learning paths](#2-learning-paths)
3. [Fundamentals (baby steps)](#3-fundamentals-baby-steps)
4. [Security principles (each with labs)](#4-security-principles-each-with-labs)
5. [Labs and evidence](#5-labs-and-evidence)
6. [Findings, audit and exceptions](#6-findings-audit-and-exceptions)
7. [Architecture, toolchain and cloud](#7-architecture-toolchain-and-cloud)
8. [Linux security](#8-linux-security)
9. [Governance, risk and compliance](#9-governance-risk-and-compliance)
10. [Career](#10-career)
11. [Capstone](#11-capstone)
12. [Reference: glossary, rules, decisions, templates](#12-reference-glossary-rules-decisions-templates)
13. [Code and configuration](#13-code-and-configuration)
14. [Make targets](#14-make-targets)

---

## 1. Start here

| Page | What it's for |
|---|---|
| [README.md](README.md) | Overview, progress table, quick start, security gates on this repo |
| [docs/security-in-practice.md](docs/security-in-practice.md) | **What this lab proves** — principle → build → evidence → lesson (for hiring/interviews) |
| [docs/career/PATHWAYS.md](docs/career/PATHWAYS.md) | Which security role to aim for from DevOps, and the plan for each |
| [docs/career/ROADMAP.md](docs/career/ROADMAP.md) | **The week-by-week plan**: 36 weeks, 5 phases, certifications |
| [docs/principles/README.md](docs/principles/README.md) | The 13 principles in learning order, each with hands-on labs |
| [docs/GLOSSARY.md](docs/GLOSSARY.md) | Every acronym and tool (SAST, DAST, SBOM, SOPS, Checkov…) with where it's used here |

---

## 2. Learning paths

| You want to… | Follow |
|---|---|
| **Start from zero** | [Baby steps](docs/basics/README.md) → [Principles 01–13](docs/principles/README.md) → [Labs](docs/labs/README.md) |
| **Move from DevOps into security** | [Pathways](docs/career/PATHWAYS.md) → [Roadmap](docs/career/ROADMAP.md) → [Career guide](docs/career/README.md) → [Capstone](docs/capstone/README.md) |
| **Understand the tools and pipeline** | [Toolchain](docs/architecture/devsecops-toolchain.md) → [Security gates script](scripts/security-scan.sh) → [Workflow](.github/workflows/security.yml) → [Glossary](docs/GLOSSARY.md) |
| **Secure cloud / Kubernetes** | [Securing the stack](docs/architecture/README.md) → [Principles 03, 04, 10](docs/principles/README.md) → [Azure labs](docs/cloud/README.md) → [Terraform](infra/azure/main.tf) |
| **Learn compliance** | [GRC](docs/grc/README.md) → [Standards](docs/grc/standards-and-regulations.md) → [Privacy/PII](docs/grc/privacy-and-pii.md) → [Payments/ATM/EDI](docs/grc/payments-atm-edi.md) |
| **Harden Linux** | [Baby step 2](docs/basics/02-linux.md) → [Linux security notes](docs/linux-security/README.md) |
| **See a real audit** | [Lab 0](docs/labs/lab-00-foundation.md) → [Lab 1](docs/labs/lab-01-cia-and-risk.md) → [Finding register](findings/README.md) → [Remediation plan](findings/REMEDIATION.md) |
| **Prepare for interviews** | "Interview questions" at the end of every principle, [toolchain](docs/architecture/devsecops-toolchain.md#9-interview-questions), [stack](docs/architecture/README.md#9-interview-questions), [Linux](docs/linux-security/README.md#18-interview-questions), [GRC](docs/grc/README.md#interview-questions) pages · [Interview prep](docs/career/README.md#interview-preparation) |

---

## 3. Fundamentals (baby steps)

| # | Page | Topic |
|---|---|---|
| — | [docs/basics/README.md](docs/basics/README.md) | Index of the 8 lessons |
| 1 | [01-networking.md](docs/basics/01-networking.md) | IP, ports, TCP, DNS, TLS |
| 2 | [02-linux.md](docs/basics/02-linux.md) | Users, permissions, processes, logs |
| 3 | [03-web.md](docs/basics/03-web.md) | HTTP, cookies, sessions, same-origin, headers |
| 4 | [04-crypto.md](docs/basics/04-crypto.md) | Encoding vs hashing vs encryption vs signing |
| 5 | [05-containers-kubernetes.md](docs/basics/05-containers-kubernetes.md) | Images, pods, namespaces, service accounts, RBAC |
| 6 | [06-git-ci.md](docs/basics/06-git-ci.md) | Git history and pipelines as security surfaces |
| 7 | [07-reading-code.md](docs/basics/07-reading-code.md) | Source → sink code review |
| 8 | [08-frameworks.md](docs/basics/08-frameworks.md) | OWASP, CWE, CVE, CVSS, NIST, CIS, ATT&CK, ISO, SOC 2 |

---

## 4. Security principles (each with labs)

| # | Principle | Labs |
|---|---|---|
| — | [Principles index](docs/principles/README.md) | How they fit together + short glossary |
| 01 | [CIA triad and risk](docs/principles/01-cia-triad-and-risk.md) | 1.1 ✅, 1.2 ✅ |
| 02 | [Threat modelling](docs/principles/02-threat-modeling.md) | 2.1 ✅, 2.2 ✅, 2.3 ✅ |
| 05 | [Attack surface](docs/principles/05-attack-surface-reduction.md) | 5.1 ✅ |
| 03 | [Least privilege](docs/principles/03-least-privilege.md) | 3.1 ✅, 3.2 ✅, 3.3 ✅ |
| 04 | [Defence in depth](docs/principles/04-defense-in-depth.md) | 4.1 ✅, 4.2 ✅ |
| 06 | [Secure defaults](docs/principles/06-secure-defaults.md) | 6.1 ✅, 6.2 ✅ |
| 07 | [Never trust input](docs/principles/07-never-trust-input.md) | 7.1 ✅, 7.3 ✅ |
| 11 | [Shift left](docs/principles/11-shift-left-automation.md) | 11.1 ✅, 11.2 ✅, 11.3 ✅ |
| 12 | [Assume breach](docs/principles/12-assume-breach.md) | 12.1 ✅ |
| 13 | [AI-era security](docs/principles/13-ai-era-security.md) | 13.1–13.5 ✅ |
| 02 | [Threat modelling](docs/principles/02-threat-modeling.md) | 2.1–2.3 |
| 03 | [Least privilege](docs/principles/03-least-privilege.md) | 3.1–3.3 |
| 04 | [Defence in depth](docs/principles/04-defense-in-depth.md) | 4.1–4.3 |
| 05 | [Minimise attack surface](docs/principles/05-attack-surface-reduction.md) | 5.1–5.3 |
| 06 | [Secure defaults, fail securely](docs/principles/06-secure-defaults.md) | 6.1–6.2 |
| 07 | [Never trust input](docs/principles/07-never-trust-input.md) | 7.1–7.3 |
| 08 | [Identity and access](docs/principles/08-identity-and-access.md) | 8.1–8.3 |
| 09 | [Protect data and secrets](docs/principles/09-protect-data-and-secrets.md) | 9.1–9.3 |
| 10 | [Supply-chain integrity](docs/principles/10-supply-chain-integrity.md) | 10.1–10.3 |
| 11 | [Shift left: security as code](docs/principles/11-shift-left-automation.md) | 11.1–11.3 |
| 12 | [Assume breach: detect and respond](docs/principles/12-assume-breach.md) | 12.1–12.3 |
| 13 | [Security in the AI era](docs/principles/13-ai-era-security.md) | 13.1–13.5 |

---

## 5. Labs and evidence

| Page | What it records |
|---|---|
| [docs/labs/README.md](docs/labs/README.md) | Status of every lab, conventions |
| [lab-00-foundation.md](docs/labs/lab-00-foundation.md) | ✅ Cluster + Juice Shop + security baseline (9 findings, 3 issues) |
| [lab-01-cia-and-risk.md](docs/labs/lab-01-cia-and-risk.md) | ✅ Asset inventory, CIA ratings, durability test (3 findings, 2 issues) |
| [lab-02-threat-modeling.md](docs/labs/lab-02-threat-modeling.md) | ✅ DFD + STRIDE (21 threats, 5 new findings) + OAuth change model |
| [lab-03-attack-surface-and-defaults.md](docs/labs/lab-03-attack-surface-and-defaults.md) | ✅ Attack-surface inventory + secure-defaults review (2 new findings, 1 downgrade) |
| [lab-04-least-privilege.md](docs/labs/lab-04-least-privilege.md) | ✅ Pod hardening: SA token, securityContext, RBAC (F-001/002/009/021 fixed) |
| [lab-05-defense-in-depth.md](docs/labs/lab-05-defense-in-depth.md) | ✅ Default-deny NetworkPolicy + Pod Security enforce (F-003/004 fixed) |
| [lab-06-virtual-patch-proxy.md](docs/labs/lab-06-virtual-patch-proxy.md) | ✅ Hardened reverse proxy blocks exposed paths (B1; F-005/006/013/014/015) |
| [lab-07-sast-supply-chain.md](docs/labs/lab-07-sast-supply-chain.md) | ✅ Custom SAST rule (F-016 regression gate) + build/scan/SBOM/sign pipeline (M2–M3) |
| [lab-08-precommit-and-baselines.md](docs/labs/lab-08-precommit-and-baselines.md) | ✅ Pre-commit hooks (gitleaks + custom SAST) + baseline/exceptions model |
| [lab-09-ai-security.md](docs/labs/lab-09-ai-security.md) | ✅ LLM chatbot review vs OWASP LLM Top 10 (F-032–F-035) |
| [lab-10-runtime-detection.md](docs/labs/lab-10-runtime-detection.md) | ✅ Falco runtime detection: triggered + triaged a real alert (ATT&CK T1003.008) |
| [lab-11-incident-game-day.md](docs/labs/lab-11-incident-game-day.md) | ✅ Incident game day: detect→contain→eradicate→recover→postmortem |
| [lab-12-ai-testing-and-process.md](docs/labs/lab-12-ai-testing-and-process.md) | ✅ AI security test plan + anti-deepfake process + verified AI triage (13.3–13.5) |
| [threat-models/README.md](threat-models/README.md) | Index of threat models |
| [threat-models/juice-shop-assets.md](threat-models/juice-shop-assets.md) | ✅ 17 assets classified and CIA-rated |
| [threat-models/juice-shop.md](threat-models/juice-shop.md) | ✅ Full app threat model: DFD + STRIDE, 21 threats |
| [threat-models/juice-shop-chatbot.md](threat-models/juice-shop-chatbot.md) | ✅ LLM chatbot threat model: OWASP LLM Top 10 |

---

## 6. Findings, audit and exceptions

| Page | What it's for |
|---|---|
| [findings/README.md](findings/README.md) | **Finding register**: all 24 issues with risk, principle, status |
| [findings/REMEDIATION.md](findings/REMEDIATION.md) | **Security audit + remediation plan**: triage of 179 scanner results, fixes, verification, gates |
| [SECURITY-EXCEPTIONS.md](SECURITY-EXCEPTIONS.md) | Accepted risks, each with reason, owner and **expiry** (enforced by CI) |
| [incidents/2026-09-26-gd1-intruder-credential-read.md](incidents/2026-09-26-gd1-intruder-credential-read.md) | Game-day incident report (detect→respond→postmortem) |
| [.trivyignore](.trivyignore) | Trivy exceptions with `exp:` dates (EXC-005) |
| [.gitleaksignore](.gitleaksignore) | Verified false positives only, with reasons |

---

## 7. Architecture, toolchain and cloud

| Page | What it's for |
|---|---|
| [docs/architecture/README.md](docs/architecture/README.md) | Securing cloud, cluster, containers/pods, code and microservices (4C model) with diagrams |
| [docs/architecture/devsecops-toolchain.md](docs/architecture/devsecops-toolchain.md) | **How the tools connect**: pipeline diagram, SAST/DAST/SCA, PR lifecycle, vulnerability reporting, SLAs |
| [docs/cloud/README.md](docs/cloud/README.md) | Azure cloud security labs AZ-1…AZ-8 and cost rules |

---

## 8. Linux security

| Page | What it's for |
|---|---|
| [docs/linux-security/README.md](docs/linux-security/README.md) | Users/sudo, permissions/SUID/**ACLs**, SELinux/AppArmor, capabilities, systemd hardening, **firewalls** (nftables/iptables/ufw/firewalld), **reverse proxies**, SSH, auditd, integrity, sysctl, patching, **built-in analysis tools**, Lynis, labs |

---

## 9. Governance, risk and compliance

| Page | What it's for |
|---|---|
| [docs/grc/README.md](docs/grc/README.md) | GRC terms, **internal/external audits** (when and how), compliance calendar, this repo as audit evidence |
| [docs/grc/standards-and-regulations.md](docs/grc/standards-and-regulations.md) | ISO 27001 family, SOC 2, **FedRAMP**, CMMC, HIPAA, SOX, SEC, CCPA, **GDPR, NIS2, DORA, CRA, EU AI Act**, other regions, overlap map |
| [docs/grc/privacy-and-pii.md](docs/grc/privacy-and-pii.md) | **PII**, privacy principles, rights, DPIAs, technical controls, breach-notification deadlines |
| [docs/grc/payments-atm-edi.md](docs/grc/payments-atm-edi.md) | **PCI DSS v4**, scope reduction, EMV and 3-D Secure, tokenisation, payment HSMs, DUKPT and PIN blocks, **ATM security**, **EDI** (AS2, X12, EDIFACT), SWIFT/ISO 20022 |
| [docs/grc/security-awareness-phishing-simulation.md](docs/grc/security-awareness-phishing-simulation.md) | How authorised phishing simulations are run, tracked and measured |

---

## 10. Career

| Page | What it's for |
|---|---|
| [docs/career/PATHWAYS.md](docs/career/PATHWAYS.md) | DevOps → DevSecOps / Cloud Security / AppSec / Detection & Response / GRC: plans, certs, proof, ways in, expert advice |
| [docs/career/ROADMAP.md](docs/career/ROADMAP.md) | 36-week plan with weekly deliverables and a progress tracker |
| [docs/career/README.md](docs/career/README.md) | Roles, skills map, real-world use cases, practice routine, portfolio, certifications, interview prep, practice platforms |

---

## 11. Capstone

| Page | What it's for |
|---|---|
| [docs/capstone/README.md](docs/capstone/README.md) | Hardened GitOps pipeline: architecture, security decisions, milestones M0–M7 |

---

## 12. Reference: glossary, rules, decisions, templates

| Page | What it's for |
|---|---|
| [docs/GLOSSARY.md](docs/GLOSSARY.md) | Terms and tools A–Z |
| [docs/security-way.md](docs/security-way.md) | Operating rules: ethics, scope, secrets, evidence |
| [docs/adr/0001-lab-application.md](docs/adr/0001-lab-application.md) | ADR: why OWASP Juice Shop |
| [docs/adr/0002-cloud-provider.md](docs/adr/0002-cloud-provider.md) | ADR: why Azure |
| [docs/adr/0003-capstone-in-this-repo.md](docs/adr/0003-capstone-in-this-repo.md) | ADR: capstone lives in this repo |
| [docs/templates/threat-model.md](docs/templates/threat-model.md) | Template: threat model |
| [docs/templates/finding.md](docs/templates/finding.md) | Template: security finding |
| [docs/templates/security-incident.md](docs/templates/security-incident.md) | Template: security incident report |

---

## 13. Code and configuration

| File | What it does |
|---|---|
| [Makefile](Makefile) | All commands (`make help`) |
| [.github/workflows/ci.yml](.github/workflows/ci.yml) | CI: manifests, custom resources, links, index completeness |
| [.github/workflows/security.yml](.github/workflows/security.yml) | Security gates (7, blocking) + SARIF reporting; weekly schedule |
| [.github/workflows/build-sign.yml](.github/workflows/build-sign.yml) | Build → Trivy scan → Syft SBOM → Cosign sign (M2–M3; activates with the app fork) |
| [.semgrep/sequelize-sqli.yaml](.semgrep/sequelize-sqli.yaml) | Custom SAST rule: SQLi regression gate for F-016 (+ self-test) |
| [scripts/ci.sh](scripts/ci.sh) | CI checks (same locally and in Actions) |
| [scripts/security-scan.sh](scripts/security-scan.sh) | The 6 security gates |
| [scripts/security-report.sh](scripts/security-report.sh) | SARIF generation for vulnerability reporting |
| [scripts/ci-install-scanners.sh](scripts/ci-install-scanners.sh) | Pinned, checksum-verified scanner install for CI |
| [scripts/check-exceptions.py](scripts/check-exceptions.py) | Fails on expired or undocumented exceptions |
| [scripts/check-links.py](scripts/check-links.py) | Fails on broken links, or pages missing from this index |
| [apps/juice-shop/juice-shop.yaml](apps/juice-shop/juice-shop.yaml) | The app's Kubernetes manifest (**hardened** in Lab 4: passes `trivy config` clean) |
| [platform/kind/cluster.yaml](platform/kind/cluster.yaml) | Local 3-node kind cluster |
| [platform/network/juice-shop-netpol.yaml](platform/network/juice-shop-netpol.yaml) | Default-deny + narrow-allow NetworkPolicy (F-003) |
| [platform/proxy/](platform/proxy/) | Hardened reverse proxy (virtual patch B1): [manifest](platform/proxy/juice-shop-proxy.yaml), [nginx.conf](platform/proxy/nginx.conf) |
| [platform/falco/values.yaml](platform/falco/values.yaml) | Falco runtime-detection config (modern eBPF); `make falco-up` / `falco-down` |
| [platform/kyverno/policies/](platform/kyverno/policies/) | Admission policies: [PSS restricted](platform/kyverno/policies/pod-security-restricted.yaml), [no SA token](platform/kyverno/policies/no-service-account-token.yaml), [trusted + pinned images](platform/kyverno/policies/images-trusted-and-pinned.yaml) |
| [platform/kyverno/cluster-only/verify-image-signatures.yaml](platform/kyverno/cluster-only/verify-image-signatures.yaml) | Signature verification (needs a live cluster) |
| [gitops/apps/juice-shop.yaml](gitops/apps/juice-shop.yaml) | Argo CD Application (selfHeal) |
| [infra/azure/](infra/azure/) | Secure-by-default AKS Terraform: [main.tf](infra/azure/main.tf), [variables.tf](infra/azure/variables.tf), [outputs.tf](infra/azure/outputs.tf), [versions.tf](infra/azure/versions.tf), [tfvars example](infra/azure/terraform.tfvars.example) |
| [.pre-commit-config.yaml](.pre-commit-config.yaml) | Pre-commit hooks (gitleaks + custom SAST), same pinned tools as CI |
| [.editorconfig](.editorconfig) · [.gitignore](.gitignore) | Formatting · what never gets committed (state, tfvars, keys, reports) |

---

## 14. Make targets

| Target | Does |
|---|---|
| `make cluster-up` / `cluster-down` | Create / delete the local kind cluster |
| `make deploy` / `undeploy` / `status` / `open` | Juice Shop lifecycle; `open` binds to 127.0.0.1 only |
| `make ci` | Manifests, custom resources, links, index completeness |
| `make security-scan` | The 6 security gates, as in CI |
| `make az-plan` / `az-up` / `az-creds` / `az-down` | Azure lab (costs money while up: **always `az-down`**) |
