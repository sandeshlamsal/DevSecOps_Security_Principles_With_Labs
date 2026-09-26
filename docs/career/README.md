# Career Study Guide: Security Engineer & DevSecOps Engineer

**This is the page to follow.** It links every lesson, principle, lab and interview question in the repo into one plan.
Work through it in order, tick the boxes as you go, and you'll finish with real lab evidence to talk about in interviews.

## Contents
1. [The roles](#the-roles)
2. [Skills map: what each role needs and where you practise it](#skills-map)
3. [Study plan](#study-plan) (full plan: [ROADMAP.md](ROADMAP.md))
4. [Real-world use cases you can now handle](#real-world-use-cases)
5. [Daily and weekly practice routine](#practice-routine)
6. [Build your portfolio from this repo](#portfolio)
7. [Certifications: which, when and why](#certifications)
8. [Interview preparation](#interview-preparation)
9. [Legal practice platforms beyond this lab](#practice-platforms)
10. [Progress checklist](#progress-checklist)

---

## The roles

| Role | What you do day to day | Typical background | Core tools |
|---|---|---|---|
| **DevSecOps Engineer** | Build security into CI/CD and platforms: scanners as gates, policy as code, secrets management, hardened images and clusters | DevOps / SRE / platform (**your strongest path**, given your Kubernetes and SRE lab work) | GitHub Actions, Semgrep, Trivy, gitleaks, Cosign, Kyverno, Terraform, Vault |
| **Application Security (AppSec) Engineer** | Threat models, secure code review, SAST/DAST triage, developer training, bug bounty triage | Software developer | Semgrep, Burp Suite, ZAP, CodeQL |
| **Cloud Security Engineer** | IAM design, landing zones, guardrails, CSPM, cloud incident response | Cloud / infrastructure | AWS/Azure/GCP native tools, Terraform, Prowler, Kubescape |
| **Security Engineer (generalist)** | A mix of all of the above, plus detection and incident response | Any of the above | Varies |
| **SOC / Detection Engineer** | Write and tune detections, triage alerts, respond to incidents | IT / sysadmin / analyst | SIEM (Splunk, Sentinel, Elastic), EDR, Falco, Sigma |
| **AI Security Engineer** (emerging) | Threat-model and test LLM features and agents, AI governance | AppSec + ML familiarity | OWASP LLM Top 10, garak, promptfoo |

**Recommended route for you:** DevSecOps first (it reuses your Kubernetes, CI/CD and SRE skills), with AppSec and Cloud Security as
the two neighbouring skills that make you stand out.

---

## Skills map

● core for the role · ○ useful

| Skill | DevSecOps | AppSec | Cloud Sec | Where you practise it |
|---|---|---|---|---|
| Networking, Linux, HTTP, crypto basics | ● | ● | ● | [Baby steps 1–4](../basics/README.md) |
| Risk-based prioritisation | ● | ● | ● | [01](../principles/01-cia-triad-and-risk.md) · [finding register](../../findings/README.md) |
| Threat modelling | ○ | ● | ● | [02](../principles/02-threat-modeling.md) |
| Kubernetes and container hardening | ● | ○ | ● | [03](../principles/03-least-privilege.md) · [04](../principles/04-defense-in-depth.md) · [stack guide](../architecture/README.md) |
| Attack-surface management | ● | ● | ● | [05](../principles/05-attack-surface-reduction.md) |
| Secure web defaults (headers, CORS, CSP) | ○ | ● | ○ | [06](../principles/06-secure-defaults.md) |
| Secure code review, SAST triage | ○ | ● | | [07](../principles/07-never-trust-input.md) · [baby step 7](../basics/07-reading-code.md) |
| AuthN/AuthZ, sessions, OAuth/JWT | ○ | ● | ● | [08](../principles/08-identity-and-access.md) |
| Secrets management | ● | ○ | ● | [09](../principles/09-protect-data-and-secrets.md) |
| Supply chain: SBOM, SCA, signing | ● | ○ | ○ | [10](../principles/10-supply-chain-integrity.md) |
| CI/CD security gates, policy as code | ● | ○ | ● | [11](../principles/11-shift-left-automation.md) |
| Detection and incident response | ○ | ○ | ● | [12](../principles/12-assume-breach.md) |
| Cloud IAM, network, logging | ○ | | ● | [Stack guide: cloud layer](../architecture/README.md#3-layer-1-cloud) |
| Microservices security (mTLS, east-west) | ● | ○ | ● | [Stack guide: microservices](../architecture/README.md#7-microservices-securing-east-west-traffic) |
| AI/LLM security | ○ | ● | ○ | [13](../principles/13-ai-era-security.md) |
| Communicating risk to engineers and managers | ● | ● | ● | Writing findings with the [finding template](../templates/finding.md) |

---

## Study plan

**Follow the [roadmap](ROADMAP.md)**: 36 weeks at ~8–10 hours a week, in five phases, with every week linked to lessons, labs and a deliverable.

| Phase | Weeks | Focus | Certification | Capstone |
|---|---|---|---|---|
| 1 | 1–6 | [Security fundamentals](ROADMAP.md#phase-1-security-fundamentals-weeks-16): principles 01–09, OWASP Top 10, STRIDE, crypto | Security+ | — |
| 2 | 7–16 | [Cloud security on Azure](ROADMAP.md#phase-2-cloud-security-on-azure-weeks-716): identity, network, Key Vault, logging, Defender, Policy | AZ-500 | M1 |
| 3 | 17–26 | [DevSecOps pipeline](ROADMAP.md#phase-3-devsecops-pipeline-security-weeks-1726): SAST, SCA, IaC, secrets, SBOM, signing | — | M2–M4 |
| 4 | 27–32 | [Kubernetes security](ROADMAP.md#phase-4-kubernetes-security-weeks-2732): RBAC, PSS, NetworkPolicy, Kyverno, Falco | CKA → CKS | M5–M6 |
| 5 | 33–36 | [Portfolio + job search](ROADMAP.md#phase-5-portfolio-and-job-search-weeks-3336) | — | M7 |

The [capstone](../capstone/README.md) (a hardened GitOps pipeline) is built step by step from Phase 3, so by Phase 5 you're polishing, not starting.

---

## Real-world use cases

Each scenario is something that happens in real security jobs. The right column shows where this repo gives you hands-on
practice, which is what to mention when an interviewer asks "have you done this?"

| # | Scenario at work | What a good engineer does | Practised in |
|---|---|---|---|
| 1 | "You've inherited a service. Is it secure?" | Inventory, exposure check, identity and privileges, network, admission controls, write findings by risk | [Lab 0](../labs/lab-00-foundation.md), [01](../principles/01-cia-triad-and-risk.md) |
| 2 | A team wants to launch a new feature next month | Lightweight threat model with the team; turn top threats into requirements and tests | [02](../principles/02-threat-modeling.md) |
| 3 | A scanner reports 300 CVEs in a production image | Prioritise by reachability, exploit data (KEV, EPSS) and exposure; fix, accept with expiry, or mark not-affected | Lab 10.2 |
| 4 | A developer pushed a cloud key to GitHub | Revoke/rotate first, check usage in audit logs, clean history, add pre-commit + CI scanning | Lab 9.3 |
| 5 | Pods run as root with the default service account across 40 namespaces | Roll out Pod Security in warn → audit → enforce; fix the top offenders; enforce in CI | Labs 3.2, 4.2, 11.1 |
| 6 | "Can we prove what's in our release and that nobody tampered with it?" | SBOM per build, signing, admission verification, provenance | Labs 10.1, 10.3 |
| 7 | A SAST tool was just switched on and developers are angry | Tune to high-confidence rules, baseline existing debt, fail only on new issues, add an exception process | Labs 7.1, 11.3 |
| 8 | Falco fires: "shell spawned in container" at 2 a.m. | Triage with the runbook, preserve evidence, contain, scope, eradicate, postmortem | Labs 12.1, 12.3 |
| 9 | Product wants to add an AI assistant that can read customer tickets and issue refunds | Threat-model with the OWASP LLM Top 10; least agency; human approval for refunds; authz outside the model | Labs 13.1–13.3 |
| 10 | Finance gets a video call from the "CFO" requesting an urgent transfer | Process-based verification out of band; controls that don't depend on spotting a deepfake | Lab 13.4 |
| 11 | The company is moving from a monolith to microservices on EKS | Workload identity, IMDS protection, default-deny NetworkPolicy, mTLS, per-service secrets, central logs | [Stack guide](../architecture/README.md) |
| 12 | An auditor asks for evidence of your security controls (SOC 2 / ISO 27001) | Show controls as code, CI history, finding register with statuses, and incident records | This whole repo |

---

## Practice routine

**Daily (20–30 minutes):**
- Read one security news item and ask "which principle failed?" Good sources: [CISA KEV](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) additions,
  [The Hacker News](https://thehackernews.com/), [tl;dr sec newsletter](https://tldrsec.com/), [Risky Business](https://risky.biz/) podcast.
- Answer one interview question from a principle page, out loud, in under 2 minutes.

**Weekly:**
- One lab session (2–4 hours) → commit the deliverable and update the [lab status](../labs/README.md).
- One exercise on a practice platform (see [below](#practice-platforms)), for example one PortSwigger Academy topic that matches this week's principle.
- Write a short "what I learned" paragraph. These become your interview stories.

---

## Portfolio

This repo **is** your portfolio. To make it count:
- Keep the [finding register](../../findings/README.md) current: open → fixed, with evidence. It shows judgement, not just tool use.
- Keep every issues log honest, including mistakes. Interviewers value "I was wrong, here's how I found out" (see Lab 0 ISSUE-3).
- Pin the repo on your GitHub profile. Add a short "What I built" section to the top-level README once a few principles are done.
- Write 2–3 blog posts from the most interesting labs (for example "Why my SAST tool's top finding was a false positive").

**Résumé bullets** (fill in the real numbers once each lab is done):
- "Built a DevSecOps lab on Kubernetes; hardened OWASP Juice Shop from 9 baseline findings to N, with Pod Security `restricted` enforced and default-deny networking."
- "Designed CI security gates (secrets, SAST, IaC, image scanning); reduced new high-severity findings merged to zero with a documented exception process."
- "Implemented supply-chain controls: SBOM per build, Cosign signing, and Kyverno admission verification of image signatures."
- "Threat-modelled an LLM chatbot against the OWASP LLM Top 10 and wrote repeatable AI security tests."

---

## Certifications

Certifications help you get past résumé filters; **labs and stories get you the job.** Pick based on your target role:

| Certification | Level | Good for | When |
|---|---|---|---|
| **CompTIA Security+** | Entry | Broad fundamentals; often a filter for first security jobs | After weeks 1–4, if you have no security cert |
| **CKS** (Certified Kubernetes Security Specialist) | Intermediate, hands-on | DevSecOps / Cloud Sec: directly matches principles 03, 04, 10, 12 | After week 11 (requires CKA first) |
| **AWS Security Specialty** / **Azure AZ-500** | Intermediate | Cloud Security roles | After the cloud-extension labs |
| **GIAC** (e.g. GCSA for cloud and DevSecOps) | Intermediate–advanced, expensive | Employer-sponsored | Later |
| **OSCP** | Advanced, offensive | Penetration testing roles | Only if you're aiming for offensive security |

---

## Interview preparation

A typical security engineering loop has four parts. Prepare for each:

| Round | What they test | How to prepare with this repo |
|---|---|---|
| **Fundamentals** | Networking, web, crypto, OWASP Top 10 | "Check yourself" in every [baby step](../basics/README.md) |
| **Technical depth** | Principles applied to their stack | The **Interview questions** section on every [principle page](../principles/README.md) and the [stack guide](../architecture/README.md#9-interview-questions) |
| **Scenario / system design** | "Design a secure pipeline", "respond to this incident", "threat-model this" | The [use cases](#real-world-use-cases) above; practise on a whiteboard |
| **Behavioural** | Collaboration, influence without authority, handling disagreement | STAR stories from your issues logs |

**Answering scenario questions.** Use the same shape every time: *clarify scope → identify assets and risks → propose layered controls
→ explain trade-offs → say how you'd verify and monitor.*

**STAR stories to prepare from your labs:**
1. A time your first conclusion was wrong (Lab 0 ISSUE-3: the NetworkPolicy count).
2. A security control that broke the app, and how you debugged it (Lab 3.2: read-only filesystem).
3. Convincing a team to accept a security gate (Lab 11.3: baselines and exceptions).
4. A finding you decided *not* to fix, and how you documented the accepted risk.

**Mock interviews.** In week 12, ask a friend (or an AI assistant, set up as the interviewer) to pick five random questions from
the principle pages and one use case. Answer out loud, with no notes, and time yourself.

---

## Practice platforms

All of these are **legal, intentionally vulnerable environments** built for learning:

| Platform | Best for | Free? |
|---|---|---|
| [PortSwigger Web Security Academy](https://portswigger.net/web-security) | The best free web-security course: every OWASP category with labs | ✅ |
| [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) score board | Deeper AppSec practice on this lab's own app | ✅ |
| [TryHackMe](https://tryhackme.com/) | Guided paths (SOC, DevSecOps, cloud) for beginners | Partly |
| [Hack The Box](https://www.hackthebox.com/) / HTB Academy | Structured modules; harder machines | Partly |
| [OverTheWire: Bandit](https://overthewire.org/wargames/bandit/) | Linux command-line fundamentals | ✅ |
| [Kubernetes Goat](https://madhuakula.com/kubernetes-goat/) | Kubernetes security scenarios (runs on kind) | ✅ |
| [flaws.cloud](http://flaws.cloud/) / [flaws2.cloud](http://flaws2.cloud/) | AWS misconfigurations, attacker and defender paths | ✅ |
| [CyberDefenders](https://cyberdefenders.org/) | Blue-team investigations: logs, forensics | Partly |
| [Gandalf (Lakera)](https://gandalf.lakera.ai/) | Prompt-injection intuition for Principle 13 | ✅ |

---

## Progress checklist

**Foundations**
- [ ] Baby steps 1–8 done, with "check yourself" answered without notes
- [x] Lab 0: cluster, app and security baseline

**Principles** (each: labs done, execution guide written, findings updated, interview questions answered out loud)
- [ ] 01 CIA & risk · [ ] 02 Threat modelling · [ ] 03 Least privilege · [ ] 04 Defence in depth
- [ ] 05 Attack surface · [ ] 06 Secure defaults · [ ] 07 Never trust input · [ ] 08 Identity & access
- [ ] 09 Data & secrets · [ ] 10 Supply chain · [ ] 11 Shift left · [ ] 12 Assume breach · [ ] 13 AI era

**Job readiness**
- [ ] Stack guide: can explain all 4 layers and the microservices section on a whiteboard
- [ ] 4 STAR stories written
- [ ] Résumé updated with real numbers from the labs
- [ ] Two mock interviews done
- [ ] Repo pinned on GitHub, top-level README shows what you built
