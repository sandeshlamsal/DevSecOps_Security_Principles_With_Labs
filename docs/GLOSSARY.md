# Security Glossary: Terms and Tools

One page for every acronym and tool name you'll meet in this repo, in job descriptions and in interviews. Each entry gives the
**plain meaning**, then **where it shows up in this lab**, so you can point to real evidence instead of a definition.

Jump to: [Testing & scanning](#1-testing-and-scanning-types) · [Supply chain](#2-software-supply-chain) ·
[Vulnerability management](#3-vulnerability-management) · [Identity & access](#4-identity-and-access) ·
[Crypto & secrets](#5-cryptography-and-secrets) · [Cloud & Kubernetes](#6-cloud-and-kubernetes) ·
[Detection & response](#7-detection-and-response) · [Attacks & weaknesses](#8-attacks-and-weaknesses) · [AI security](#9-ai-security) ·
[Frameworks](#10-frameworks-and-standards) · [**Tools A–Z**](#11-tools-a-z)

See how the tools connect in the [DevSecOps toolchain](architecture/devsecops-toolchain.md).

---

## 1. Testing and scanning types

| Term | Stands for | Plain meaning | In this lab |
|---|---|---|---|
| **SAST** | Static Application Security Testing | Reads source code **without running it**, looking for insecure patterns (e.g. input pasted into SQL) | Semgrep found SQL injection in `routes/login.ts:34` (F-016) |
| **DAST** | Dynamic Application Security Testing | Tests the **running** app from outside by sending HTTP requests and inspecting responses, like an attacker would | ZAP planned (week 21); the manual header checks in Lab 0 were "DAST by hand" (F-007, F-008) |
| **IAST** | Interactive Application Security Testing | An agent inside the running app watches data flow while tests run: combines SAST and DAST views | Not used (mostly commercial) |
| **SCA** | Software Composition Analysis | Finds known-vulnerable **third-party** libraries in your dependencies | Trivy found 53 High/Critical CVEs in the image (F-017) |
| **IaC scanning** | Infrastructure as Code scanning | Checks Terraform, Kubernetes YAML and Dockerfiles for misconfigurations before deploy | Checkov on `infra/azure`, Trivy config on `apps/` |
| **Secrets scanning** | — | Finds passwords, API keys and private keys in code **and git history** | gitleaks found the JWT private key (F-010) |
| **Container / image scanning** | — | SCA for everything inside a container image: OS packages + app libraries | `trivy image` in the weekly report job |
| **Fuzzing** | — | Feeding huge amounts of random or malformed input to find crashes and unexpected behaviour | Not yet |
| **Pentest** | Penetration test | Authorised, human-led attempt to break in, within an agreed scope | Out of scope; this lab is defensive |
| **Shift left** | — | Moving security checks earlier (to the PR or the laptop) where fixes are cheaper | [Principle 11](principles/11-shift-left-automation.md) |
| **Security gate** | — | A pipeline step that **fails the build** when it finds a problem | 6 gates in [security-scan.sh](../scripts/security-scan.sh) |
| **False positive / negative** | — | FP: tool flags something that isn't a real issue. FN: tool misses a real issue | The JWT-header gitleaks hit (FP); Trivy's "runs as root" on a non-root image (technically FP, rightly flagged) |
| **Triage** | — | Deciding for each finding: real? reachable? how risky? fix, accept or dismiss? | 179 raw results → 24 issues in [REMEDIATION.md](../findings/REMEDIATION.md) |
| **Baseline** | — | Recording existing findings so a gate fails only on **new** ones | Planned in Lab 11.3 |

## 2. Software supply chain

| Term | Stands for | Plain meaning | In this lab |
|---|---|---|---|
| **SBOM** | Software Bill of Materials | A complete **ingredient list** of a piece of software: every library, version and licence | Syft planned (week 22); answers "do we ship Log4j?" in minutes |
| **CycloneDX / SPDX** | — | The two standard SBOM file formats (JSON/XML) | CycloneDX planned |
| **VEX** | Vulnerability Exploitability eXchange | A statement saying whether a CVE in your SBOM **actually affects** you (e.g. "not affected: code not reachable") | Used when triaging F-017 (Lab 10.2) |
| **Provenance** | — | Signed metadata about **how and where** an artifact was built (which repo, commit, workflow) | Planned with Cosign (week 23) |
| **Attestation** | — | A signed claim attached to an artifact (provenance, SBOM, scan result) | Planned |
| **SLSA** | Supply-chain Levels for Software Artifacts | A framework of levels (1–3) for build integrity: scripted build, provenance, hardened builder | Target for the capstone |
| **Signing (image signing)** | — | Cryptographically proving an image came from you and wasn't changed | Cosign keyless (week 23) |
| **Sigstore / Rekor / Fulcio** | — | Free public signing infrastructure: Fulcio issues short-lived certificates, Rekor is a public tamper-evident log | Used by Cosign keyless signing |
| **Keyless signing** | — | Signing with a short-lived certificate tied to an identity (e.g. a GitHub Actions workflow), so there's no long-lived key to leak | [verify-image-signatures.yaml](../platform/kyverno/cluster-only/verify-image-signatures.yaml) |
| **Digest pinning** | — | Referencing an image by its content hash (`@sha256:…`), which can't be changed, instead of a tag, which can | F-009; Kyverno `pinned-by-digest` rule |
| **Action pinning** | — | Referencing a GitHub Action by commit SHA instead of a movable tag | F-023, fixed |
| **Dependency confusion / typosquatting / slopsquatting** | — | Tricking a build into installing a malicious package: same name on a public registry / a look-alike name / a name an AI assistant invented | F-024 (npm minimum release age) |

## 3. Vulnerability management

| Term | Stands for | Plain meaning | In this lab |
|---|---|---|---|
| **CVE** | Common Vulnerabilities and Exposures | A unique ID for one **specific** public vulnerability (e.g. CVE-2021-44228 = Log4Shell) | 53 CVEs in F-017 |
| **CWE** | Common Weakness Enumeration | A **category** of weakness (CWE-89 = SQL injection) | Every Semgrep result carries a CWE |
| **CVSS** | Common Vulnerability Scoring System | A 0–10 severity score for a vulnerability, **without your context** | Trivy severities come from CVSS |
| **EPSS** | Exploit Prediction Scoring System | The probability a CVE will be exploited in the next 30 days | Used to prioritise F-017 |
| **KEV** | CISA Known Exploited Vulnerabilities | A list of CVEs **known** to be exploited in the wild: patch these first | 7-day SLA in the [toolchain](architecture/devsecops-toolchain.md#7-fix-time-targets-slas-and-exceptions) |
| **NVD / GHSA** | National Vulnerability Database / GitHub Security Advisory | Public vulnerability databases scanners use | Trivy IDs like `GHSA-5mrr-…` |
| **SARIF** | Static Analysis Results Interchange Format | Standard JSON format for scanner results, so any tool's findings can be shown in one place | Uploaded to GitHub's Security tab ✅ |
| **Reachability** | — | Whether vulnerable code can actually be **called** by your app. Unreachable = lower risk | Lab 10.2 |
| **Risk acceptance / exception** | — | A documented decision not to fix (yet), with an owner, a reason and an **expiry** | [SECURITY-EXCEPTIONS.md](../SECURITY-EXCEPTIONS.md) |
| **Remediation SLA** | — | Maximum time to fix by severity (e.g. Critical 7 days) | [SLA table](architecture/devsecops-toolchain.md#7-fix-time-targets-slas-and-exceptions) |
| **Zero-day** | — | A vulnerability exploited before a fix exists | Why detection ([Principle 12](principles/12-assume-breach.md)) matters |
| **Virtual patch** | — | Blocking an attack at the edge (proxy/WAF) before the code is fixed | Plan step B1 |

## 4. Identity and access

| Term | Stands for | Plain meaning | In this lab |
|---|---|---|---|
| **AuthN / AuthZ** | Authentication / Authorisation | Who are you? / What may you do? | [Principle 08](principles/08-identity-and-access.md) |
| **MFA** | Multi-Factor Authentication | Two or more of: something you know, have, are | Phishing-resistant MFA in [Principle 13](principles/13-ai-era-security.md) |
| **FIDO2 / WebAuthn / passkey** | — | Phishing-resistant login with a hardware key or device, tied to the real website | Recommended for admins |
| **SSO** | Single Sign-On | One login for many apps, through an identity provider | Entra ID for AKS |
| **OAuth 2.0 / OIDC** | Open Authorization / OpenID Connect | OAuth: delegated access tokens. OIDC: identity layer on top (who logged in) | GitHub OIDC for keyless signing; AKS OIDC issuer |
| **JWT** | JSON Web Token | A signed token carrying claims (user, role, expiry). Encoded, **not encrypted** | Juice Shop sessions; F-010 |
| **RBAC / ABAC** | Role-/Attribute-Based Access Control | Permissions via roles / via attributes (department, tag, time) | Kubernetes RBAC (Lab 3.3), Azure RBAC (AZ-2) |
| **Least privilege** | — | Only the access needed, only for as long as needed | [Principle 03](principles/03-least-privilege.md) |
| **PIM / JIT access** | Privileged Identity Management / Just-In-Time | Admin rights granted temporarily on request, then removed | Phase 2 identity weeks |
| **Service account** | — | An identity for software, not a person | F-001 (default SA token mounted) |
| **Workload identity** | — | A pod gets a cloud identity through federation, with **no stored secret** | Terraform `juice_shop` identity; lab AZ-4 |
| **IDOR** | Insecure Direct Object Reference | Changing an ID in a request (`/orders/1002`) to reach someone else's data | Lab 8.2 |

## 5. Cryptography and secrets

| Term | Plain meaning | In this lab |
|---|---|---|
| **Encoding** (Base64) | Changing format. **Not security**: anyone can reverse it | Kubernetes Secrets are only Base64 (Lab 9.2) |
| **Hashing** | One-way fingerprint (SHA-256) for integrity | File checksums verified in CI |
| **Password hashing / salt** | *Slow*, salted one-way hash (bcrypt, Argon2id) so leaked hashes are hard to crack | F-011: Juice Shop uses unsalted MD5 |
| **Symmetric / asymmetric encryption** | One shared key (AES) / a public + private key pair (RSA, ECDSA) | JWT signing uses RS256 (asymmetric) |
| **Digital signature** | Private key signs, public key verifies: proves origin and integrity | Cosign, JWTs |
| **TLS / mTLS** | Encrypts connections and proves the server's identity / both sides prove identity | Service mesh in the [stack guide](architecture/README.md#7-microservices-securing-east-west-traffic) |
| **PKI / certificate** | The system of certificate authorities that vouches for public keys | Baby step 1 (`curl -v` shows the cert) |
| **KMS / HSM** | Key Management Service / Hardware Security Module: store and use keys without exposing them | Azure Key Vault |
| **Envelope encryption** | Data encrypted with a data key; the data key encrypted with a master key in the KMS | Principle 09 interview question |
| **Secret rotation** | Replacing a secret regularly, and **immediately** after a leak | Plan step C2 |
| **Secrets manager** | A service that stores, controls access to and rotates secrets | Key Vault; Vault (optional) |
| **SOPS / age** | Encrypts secret values inside YAML so they can live in Git safely / a simple modern encryption tool SOPS can use | Capstone M4 |

## 6. Cloud and Kubernetes

| Term | Stands for | Plain meaning | In this lab |
|---|---|---|---|
| **Shared responsibility** | — | The cloud provider secures the platform; **you** secure your config, identities, data and workloads | [Stack guide §2](architecture/README.md#2-the-same-app-in-a-real-cloud) |
| **CSPM** | Cloud Security Posture Management | Continuously checks cloud config against best practices | Defender for Cloud (AZ-7) |
| **CWPP / CNAPP** | Cloud Workload Protection Platform / Cloud-Native Application Protection Platform | Runtime protection for workloads / a bundle of CSPM + CWPP + code scanning | Defender for Containers |
| **KSPM** | Kubernetes Security Posture Management | CSPM for Kubernetes clusters | Kubescape, kube-bench |
| **IMDS** | Instance Metadata Service | A cloud VM's internal endpoint that can hand out credentials, a classic SSRF target | [Stack guide §3](architecture/README.md#3-layer-1-cloud) |
| **PSS / PSA** | Pod Security Standards / Pod Security Admission | Three levels (privileged, baseline, restricted) / the built-in controller that enforces them per namespace | F-004; plan step A3 |
| **Admission controller** | — | Checks (and can reject) objects when they're created in Kubernetes | Kyverno |
| **Policy as code** | — | Security rules written as versioned code and enforced automatically | Kyverno policies, Azure Policy, Checkov |
| **NetworkPolicy** | — | Kubernetes firewall rules between pods | F-003; plan step A2 |
| **securityContext / seccomp / capabilities** | — | Per-pod settings: user, privilege escalation, syscall filtering, Linux root powers | F-002; plan step A1 |
| **Distroless** | — | A container image with only the app and its runtime: no shell, no package manager | Juice Shop's image (positive observation) |
| **Zero trust** | — | Never trust by network location; verify every request | [Principle 04](principles/04-defense-in-depth.md) |
| **Service mesh** | — | A layer (Istio, Linkerd) that adds mTLS, identity and policy to service-to-service traffic | Microservices section |
| **GitOps / drift** | — | Git is the source of truth and a controller applies it / the cluster differing from Git | Argo CD with `selfHeal` |
| **North-south / east-west** | — | Traffic into the system / traffic between internal services | [Stack guide §7](architecture/README.md#7-microservices-securing-east-west-traffic) |

## 7. Detection and response

| Term | Stands for | Plain meaning | In this lab |
|---|---|---|---|
| **SIEM** | Security Information and Event Management | Collects and correlates logs from everywhere; raises alerts | Microsoft Sentinel (Phase 2) |
| **SOAR** | Security Orchestration, Automation and Response | Automated response playbooks | Concept |
| **EDR / XDR** | Endpoint / Extended Detection and Response | Agents that detect and respond to threats on hosts / across many sources | Defender |
| **SOC** | Security Operations Centre | The team that monitors and responds to alerts | Career guide roles |
| **IR** | Incident Response | The process: prepare → detect & analyse → contain, eradicate, recover → learn | [Principle 12](principles/12-assume-breach.md) |
| **IOC / TTP** | Indicator of Compromise / Tactics, Techniques and Procedures | Evidence of an attack (IP, hash) / *how* attackers operate | ATT&CK mapping of Falco rules |
| **MTTD / MTTR** | Mean Time To Detect / Respond (or Recover) | How fast you notice and fix | Game day (Lab 12.3) |
| **Threat hunting** | — | Proactively searching for attackers who evaded alerts | Concept |
| **Red / blue / purple team** | — | Attackers / defenders / both working together to improve detection | This lab is blue-team focused |
| **Audit log** | — | A tamper-resistant record of who did what, and when | K8s audit logs (12.2), Azure Activity Log (AZ-6) |

## 8. Attacks and weaknesses

| Term | Plain meaning | In this lab |
|---|---|---|
| **OWASP Top 10** | The 10 most critical web app risk categories | Juice Shop covers all of them |
| **Injection (SQLi, command injection)** | Untrusted input treated as code by an interpreter | F-016 |
| **XSS** (Cross-Site Scripting) | Attacker's script runs in another user's browser | CSP (F-008) is a second layer |
| **CSRF** (Cross-Site Request Forgery) | Tricking a logged-in user's browser into sending a request | `SameSite` cookies |
| **SSRF** (Server-Side Request Forgery) | Making the server fetch a URL the attacker chooses, often internal | IMDS risk; Capital One breach |
| **RCE** (Remote Code Execution) | Running attacker code on the server | F-019 (possible code injection) |
| **Path traversal** | Using `../` to read files outside the intended folder | F-018 (to triage) |
| **Open redirect** | The site redirects users to an attacker-chosen URL (phishing aid) | F-020 (to triage) |
| **Privilege escalation** | Gaining more rights than you should have | Pod `allowPrivilegeEscalation` (F-002) |
| **Lateral movement** | Moving from one compromised system to others | Flat network (F-003) |
| **Information disclosure** | Leaking data or internals | F-005, F-013, F-014, F-015 |
| **Supply-chain attack** | Compromising software you trust (a library, build system or update) | SolarWinds, xz utils in [Principle 10](principles/10-supply-chain-integrity.md) |
| **Phishing / social engineering** | Tricking people into giving access or money | AI-driven phishing in Principle 13 |
| **Blast radius** | How much damage one compromised part can do | Least privilege limits it |
| **Attack surface** | Every way an attacker can interact with the system | [Principle 05](principles/05-attack-surface-reduction.md) |

## 9. AI security

| Term | Plain meaning | In this lab |
|---|---|---|
| **Prompt injection (direct / indirect)** | Instructions in user input / in content the model reads (web page, document) override intended behaviour | [Principle 13](principles/13-ai-era-security.md), LLM01 |
| **Jailbreak** | Getting a model to ignore its safety rules | Awareness |
| **Excessive agency** | An AI agent has more tools or permissions than its task needs | LLM06; least agency |
| **Data / model poisoning** | Manipulating training or fine-tuning data | LLM04 |
| **RAG** | Retrieval-Augmented Generation: the model looks up documents to answer | LLM08 (vector store access) |
| **Deepfake** | AI-generated fake audio or video of a real person | Lab 13.4 payment process |
| **OWASP LLM Top 10 / MITRE ATLAS** | Top risks for LLM apps / ATT&CK-style catalogue of attacks on AI | Principle 13 |

## 10. Frameworks and standards

Full cheat sheet: [baby step 8](basics/08-frameworks.md). In brief: **NIST CSF** (programme), **ISO 27001 / SOC 2** (certification/audit),
**CIS Benchmarks** (hardening), **OWASP ASVS** (app requirements), **MITRE ATT&CK** (attacker techniques), **PCI DSS** (card data),
**GDPR** (personal data), **SLSA** (build integrity), **NIST SP 800-61** (incident handling).

---

## 11. Tools A–Z

| Tool | Category | What it does | In this repo |
|---|---|---|---|
| **Argo CD** | GitOps | Deploys from Git and reverts drift | 🟡 [gitops/apps/](../gitops/apps/) |
| **Burp Suite** | DAST / manual testing | Intercepting proxy used by AppSec engineers and pentesters | Recommended with PortSwigger Academy |
| **Checkov** | **IaC scanning** | Scans Terraform, CloudFormation, Kubernetes, Dockerfiles and GitHub workflows for misconfigurations against 1,000+ built-in policies (e.g. "AKS API server has authorised IP ranges"). Supports inline skips with reasons | ✅ Gate 4 on `infra/azure`: 18 passed, 0 failed, 8 documented skips |
| **CodeQL** | SAST | GitHub's semantic code analysis: tracks data flow from source to sink across files | ⏳ week 18 |
| **Cosign** | Supply chain | Signs and verifies container images and attestations (Sigstore) | ⏳ week 23 |
| **DefectDojo** | Vuln management | Aggregates results from 150+ scanners; dedupes; tracks SLAs and risk acceptance | ⏳ Phase 3 stretch |
| **Defender for Cloud** | CSPM / CWPP | Azure's posture management and workload threat detection | ⏳ AZ-7 |
| **Dependabot** | SCA | Opens PRs to update vulnerable dependencies | ⏳ week 20 |
| **Dependency-Track** | SBOM monitoring | Stores SBOMs and alerts when new CVEs affect them | ⏳ week 22 |
| **External Secrets Operator** | Secrets | Syncs secrets from Key Vault/Vault into Kubernetes | ⏳ M4 |
| **Falco** | Runtime detection | Watches system calls and alerts on suspicious behaviour (shell in container) | ⏳ M6 |
| **garak / promptfoo** | AI security testing | Automated probes and evaluations for LLM apps | ⏳ Lab 13.3 |
| **gitleaks** | Secrets scanning | Finds secrets in files and git history | ✅ Gate 1 |
| **Grype** | SCA / image scanning | Vulnerability scanner that pairs with Syft SBOMs | Alternative to Trivy |
| **KICS** | IaC scanning | Open-source IaC scanner (Checkmarx) | Alternative to Checkov |
| **kube-bench** | KSPM | Checks nodes against the CIS Kubernetes Benchmark | Stack guide |
| **Kubescape** | KSPM | Scans clusters and manifests against NSA/CISA and CIS frameworks | Stack guide |
| **Kyverno** | Policy as code / admission | Kubernetes-native policies: validate, mutate, verify image signatures | 🟡 [platform/kyverno/](../platform/kyverno/), Gate 6 (report) |
| **OPA / Gatekeeper** | Policy as code | General policy engine (Rego) / its Kubernetes admission controller; Azure Policy for AKS uses Gatekeeper | Azure Policy add-on in Terraform |
| **OWASP ZAP** | DAST | Open-source web scanner: baseline (passive), full (active), API scans | ⏳ week 21 |
| **Semgrep** | SAST | Fast, rule-based code scanner; easy custom rules | ✅ Gate 2 (workflows); audit of Juice Shop source |
| **Sentinel** | SIEM | Microsoft's cloud SIEM | ⏳ Phase 2 |
| **Snyk** | SCA / SAST | Commercial developer security platform (free tier) | Optional |
| **SonarQube** | SAST / code quality | Code quality + security hotspots | Optional |
| **SOPS** | Secrets (GitOps) | *Secrets OPerationS* (by Mozilla, now CNCF). Encrypts only the **values** in a YAML/JSON/.env file and leaves the keys readable, so encrypted secrets can live in Git and diffs still make sense. It encrypts with **age** keys, PGP, or a cloud KMS (e.g. Azure Key Vault). A `.sops.yaml` file says which files and fields to encrypt, with which key. At deploy time, Argo CD (via a plugin such as KSOPS) or Flux decrypts it inside the cluster. Only holders of the private key can read the values. Example: `sops --encrypt --age <public-key> secret.yaml > secret.enc.yaml` | ⏳ capstone M4 (week 24) |
| **Syft** | SBOM | Generates SBOMs (CycloneDX, SPDX) from images and directories | ⏳ week 22 |
| **Trivy** | SCA / image / IaC / K8s | All-in-one scanner: images, filesystems, Kubernetes config, Terraform (tfsec is now part of it), SBOMs | ✅ Gate 3 (config) + weekly image report |
| **TruffleHog** | Secrets scanning | Finds secrets and **verifies** whether they're still live | ⏳ week 19 |
| **Vault** | Secrets | HashiCorp's secrets manager: dynamic secrets, leasing, rotation | Optional |
