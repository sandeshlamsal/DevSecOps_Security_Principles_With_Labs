# Baby Step 8: Frameworks Cheat Sheet

Job descriptions and interviews use these names constantly. Know what each is **for**:

| Name | What it is | When you'll use it |
|---|---|---|
| **OWASP Top 10** | The 10 most critical web app risk categories (2021 edition; 2025 update) | AppSec basics, every interview |
| **OWASP ASVS** | A detailed checklist of web app security requirements, in three levels | Security requirements, audits, Principle 10 readiness |
| **OWASP Top 10 for LLM Apps** | Top risks for LLM and agent features | [Principle 13](../principles/13-ai-era-security.md) |
| **CWE** | Catalogue of weakness *types* (CWE-89 = SQL injection) | Classifying findings |
| **CVE** | ID for a specific public vulnerability (CVE-2021-44228 = Log4Shell) | Patching, SCA |
| **CVSS** | 0–10 severity score for a vulnerability | Prioritising, together with context |
| **EPSS / CISA KEV** | Probability of exploitation / list of vulns **known** to be exploited | Deciding what to patch first |
| **MITRE ATT&CK** | Catalogue of real attacker tactics and techniques | Detection engineering, threat intel |
| **MITRE ATLAS** | ATT&CK-style catalogue for attacks on AI systems | AI security |
| **NIST CSF 2.0** | Govern, Identify, Protect, Detect, Respond, Recover | Security programmes, management conversations |
| **NIST SP 800-61** | Incident-handling guide | Incident response |
| **CIS Benchmarks** | Hardening guides for OSes, Kubernetes, clouds | Hardening, audits (kube-bench) |
| **SLSA** | Levels of build integrity for the supply chain | DevSecOps, supply chain |
| **ISO 27001 / SOC 2** | Certifiable security management standard / audit report on controls | Compliance, customer questionnaires |
| **PCI DSS** | Rules for handling payment-card data | Any company taking cards |
| **GDPR** | EU data-protection law | Anything handling personal data |

**Go deeper:** the [GRC section](../grc/README.md) covers audits, each standard and regulation, privacy, and payments security in detail.

## Check yourself
1. CVE vs CWE: which is a specific bug, and which is a category?
2. A CVSS 9.8 isn't on the CISA KEV list; a CVSS 7.5 is. Which do you patch first, and why?
3. Which framework would you use to explain your security programme to executives?
