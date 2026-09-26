# Security Standards and Regulations

Which standards IT companies adhere to, which laws apply where, and what each actually requires. ← [GRC index](README.md)

> Checked as of **September 2026**. Laws and standards change. Confirm dates, thresholds and versions against the official source.

## Contents
1. [Which ones apply to a typical IT/SaaS company?](#1-which-ones-apply-to-a-typical-itsaas-company)
2. [International standards (ISO/IEC)](#2-international-standards-isoiec)
3. [SOC reports (AICPA, United States)](#3-soc-reports-aicpa-united-states)
4. [United States: federal and sector rules](#4-united-states-federal-and-sector-rules)
5. [European Union](#5-european-union)
6. [Other regions](#6-other-regions)
7. [Industry-specific standards](#7-industry-specific-standards)
8. [Frameworks (voluntary guidance)](#8-frameworks-voluntary-guidance)
9. [How they overlap: build once, comply many](#9-how-they-overlap-build-once-comply-many)
10. [Interview questions](#10-interview-questions)

---

## 1. Which ones apply to a typical IT/SaaS company?

| If you… | You'll likely need |
|---|---|
| Sell B2B software or cloud services | **SOC 2 Type II** (especially US customers) and/or **ISO 27001** (especially international and EU customers) |
| Process personal data of people in the EU/UK | **GDPR / UK GDPR**; often **ISO 27701** to show a privacy management system |
| Process personal data of California residents (above thresholds) | **CCPA/CPRA** (plus other US state privacy laws) |
| Store, process or transmit payment card data | **PCI DSS** ([payments page](payments-atm-edi.md)) |
| Handle US health data for covered entities | **HIPAA** (sign Business Associate Agreements) |
| Sell cloud services to US federal agencies | **FedRAMP** |
| Work in the US defence supply chain | **CMMC** (protecting FCI/CUI, based on NIST SP 800-171) |
| Are publicly listed in the US | **SOX** (IT general controls over financial reporting) + **SEC** cyber incident disclosure |
| Provide essential or important services in the EU | **NIS2** |
| Are an EU financial entity or its critical ICT provider | **DORA** |
| Sell products with digital elements in the EU | **Cyber Resilience Act** (phasing in) |
| Build or deploy AI systems in the EU | **EU AI Act** (phasing in); optionally **ISO/IEC 42001** |

---

## 2. International standards (ISO/IEC)

| Standard | What it is | Certifiable? |
|---|---|---|
| **ISO/IEC 27001:2022** | Requirements for an **Information Security Management System (ISMS)**: risk assessment, risk treatment, leadership, internal audit, continual improvement (clauses 4–10) + **Annex A: 93 controls** in 4 themes: organisational (37), people (8), physical (14), technological (34). The transition period from the 2013 version ended in October 2025 | ✅ Yes, the main one |
| **ISO/IEC 27002:2022** | Guidance on *how* to implement each Annex A control | No (guidance) |
| **ISO/IEC 27017** | Cloud-specific security controls (for providers and customers) | Usually assessed alongside 27001 |
| **ISO/IEC 27018** | Protecting PII in public clouds acting as processors | Usually alongside 27001 |
| **ISO/IEC 27701** | **Privacy** Information Management System (PIMS): maps well to GDPR. The 2025 edition can be certified on its own | ✅ |
| **ISO/IEC 27005** | Information security risk management guidance | No |
| **ISO 22301** | Business continuity management | ✅ |
| **ISO/IEC 42001:2023** | **AI management system**: governance of AI development and use | ✅ |
| **ISO/IEC 20000-1** | IT service management | ✅ |

**ISO 27001 certification cycle:** gap analysis → build the ISMS (scope, risk assessment, Statement of Applicability, policies) → run it for a few months
→ internal audit + management review → **Stage 1** audit (documentation) → **Stage 2** audit (is it working?) → certificate valid 3 years, with
**surveillance audits every year** → recertification.

---

## 3. SOC reports (AICPA, United States)

| Report | What it covers | Audience |
|---|---|---|
| **SOC 1** | Controls relevant to customers' **financial reporting** (e.g. payroll, billing processors) | Customers' auditors |
| **SOC 2** | Controls against the **Trust Services Criteria**: **Security** (required, the "Common Criteria" CC1–CC9), plus optional Availability, Processing Integrity, Confidentiality, Privacy | Customers (under NDA) |
| **SOC 3** | Public summary of a SOC 2 | Anyone (marketing) |
| **Type I vs Type II** | Type I: controls *designed* properly at a point in time. **Type II**: controls *operated* effectively over a period (typically 3–12 months) | Type II is what customers expect |

SOC 2 isn't a certification: it's an **attestation report** by a licensed CPA firm. Its scope and controls are defined by the company, which
makes it flexible, but customers read the report to judge the details.

---

## 4. United States: federal and sector rules

| Name | Applies to | Key points |
|---|---|---|
| **FedRAMP** (Federal Risk and Authorization Management Program) | Cloud services used by US federal agencies | Standardised security assessment based on **NIST SP 800-53 Rev 5** controls. Impact levels **Low, Moderate, High** (+ LI-SaaS for low-impact SaaS), set using FIPS 199. An accredited **3PAO** (third-party assessment organisation) assesses; an agency grants an **Authorization to Operate (ATO)**; then **continuous monitoring** (monthly scans, POA&M tracking, annual assessment). The programme is being modernised (the "FedRAMP 20x" initiative, emphasising automated, machine-readable evidence), so check the current process at fedramp.gov |
| **StateRAMP** | Cloud services for US state and local government | Modelled on FedRAMP |
| **FISMA** | Federal agencies and their contractors' systems | NIST RMF (SP 800-37) + SP 800-53 controls |
| **CMMC 2.0** (Cybersecurity Maturity Model Certification) | US Department of Defense contractors | Level 1 (basic, Federal Contract Information), Level 2 (**NIST SP 800-171**'s 110 requirements for Controlled Unclassified Information, usually with a third-party assessment), Level 3 (adds SP 800-172). The programme rule took effect in December 2024 and is being phased into DoD contracts from late 2025 |
| **NIST SP 800-171** | Non-federal systems holding CUI | 110 security requirements; basis for CMMC Level 2 |
| **HIPAA** (Security, Privacy and Breach Notification Rules) | Health plans, providers, clearinghouses + their **business associates** | Administrative, physical, technical safeguards for electronic protected health information (ePHI); risk analysis; BAAs; breach notification to individuals without unreasonable delay and **no later than 60 days** after discovery |
| **HITRUST CSF** | Healthcare (and others), voluntary | Certifiable framework that harmonises HIPAA, ISO, NIST and more |
| **SOX** (Sarbanes-Oxley) §404 | US-listed public companies | Internal control over financial reporting, which includes **IT general controls (ITGCs)**: access, change management, operations for financial systems |
| **SEC cybersecurity disclosure rules** | US-listed public companies | Disclose a **material** cybersecurity incident on Form 8-K (Item 1.05) within **4 business days** of determining it's material; annual disclosure of cyber risk management and governance (10-K) |
| **GLBA** (Gramm-Leach-Bliley Act) + FTC Safeguards Rule | Financial institutions (broadly defined, including many fintechs) | Written information security programme, a qualified individual in charge, risk assessment, encryption, MFA, and notifying the FTC of certain breaches |
| **NYDFS 23 NYCRR 500** | Financial services regulated in New York | CISO, risk-based programme, MFA, asset inventory, 72-hour incident notification, annual certification |
| **CCPA / CPRA** | Businesses handling California residents' personal data above thresholds | Rights to know, delete, correct and opt out of sale/sharing; "reasonable security"; enforced by the California Privacy Protection Agency. Many other states now have similar comprehensive privacy laws |
| **COPPA** | Online services directed at children under 13 | Parental consent for collecting children's data |
| **CISA / CIRCIA** | Critical infrastructure | Incident and ransomware-payment reporting to CISA; final rule timing has shifted, so check its current status |

---

## 5. European Union

| Name | Applies to | Key points |
|---|---|---|
| **GDPR** (General Data Protection Regulation) | Anyone processing personal data of people in the EU, wherever the company is | Lawful basis, data-protection principles, data-subject rights, security of processing (Art. 32), **breach notification to the supervisory authority within 72 hours** (Art. 33), DPIAs for high-risk processing, DPOs in some cases, strict rules for transfers outside the EU. Fines up to **€20 million or 4% of worldwide annual turnover**, whichever is higher. See [privacy page](privacy-and-pii.md) |
| **NIS2 Directive** | "Essential" and "important" entities in 18 sectors (energy, transport, banking, health, digital infrastructure, cloud, data centres, managed service providers, and more) | Risk-management measures, **management accountability** (leaders can be held liable), supply-chain security, incident reporting: **early warning within 24 hours**, notification within 72 hours, final report within one month. Applied through national laws (transposition deadline October 2024) |
| **DORA** (Digital Operational Resilience Act) | EU financial entities + critical ICT third-party providers | Applies since **17 January 2025**. ICT risk management, major-incident reporting, digital operational resilience **testing** (including threat-led penetration testing for significant entities), third-party (ICT supplier) risk management and register |
| **Cyber Resilience Act (CRA)** | Manufacturers of products with digital elements (hardware and software) sold in the EU | Secure-by-design requirements, vulnerability handling, **SBOM**, security updates for the support period, CE marking. In force since December 2024; vulnerability and incident **reporting obligations from September 2026**; most obligations from **December 2027** |
| **EU AI Act** | Providers and deployers of AI systems in the EU | Risk-based: prohibited practices, high-risk systems (strict requirements, including cybersecurity and robustness), transparency duties, general-purpose AI model obligations. Obligations phase in from 2025 to 2027 |
| **eIDAS 2.0** | Electronic identification and trust services | EU Digital Identity Wallet, qualified signatures and certificates |
| **ePrivacy Directive** | Electronic communications | Cookies and tracking consent, confidentiality of communications |

---

## 6. Other regions

| Region | Law / scheme | Notes |
|---|---|---|
| United Kingdom | **UK GDPR** + Data Protection Act 2018; **Cyber Essentials / Cyber Essentials Plus** | Cyber Essentials is a basic certification often required for UK government contracts |
| Canada | **PIPEDA** (federal private sector) + provincial laws (e.g. Quebec Law 25) | Breach reporting to the Privacy Commissioner |
| India | **Digital Personal Data Protection Act 2023** (rules being phased in) + CERT-In directions | CERT-In requires reporting certain incidents within **6 hours** |
| Singapore | **PDPA** + MAS Technology Risk Management guidelines (financial) | |
| Australia | **Privacy Act 1988** (Notifiable Data Breaches scheme), **Essential Eight** (ASD), APRA CPS 234 (financial) | |
| Brazil | **LGPD** | GDPR-like |
| Global | **SWIFT Customer Security Programme (CSP/CSCF)** | Annual attestation for banks on the SWIFT network ([payments page](payments-atm-edi.md)) |

---

## 7. Industry-specific standards

| Standard | Industry | See |
|---|---|---|
| **PCI DSS v4.0.1** | Anyone handling payment card data | [Payments page](payments-atm-edi.md) |
| **PCI PIN Security, PCI PTS, PCI P2PE, PCI 3DS, PCI Secure Software Framework** | Payment devices, PIN handling, card processors, payment software vendors | [Payments page](payments-atm-edi.md) |
| **HIPAA / HITRUST** | Healthcare | §4 |
| **NERC CIP** | North American bulk electric system | Utilities |
| **IEC 62443** | Industrial control systems / OT | Manufacturing, energy |
| **ISO/SAE 21434, UN R155** | Automotive cybersecurity | Vehicle makers |
| **TISAX** | German automotive supply chain | Based on the VDA ISA catalogue |
| **CJIS Security Policy** | US criminal justice information | Law enforcement suppliers |

---

## 8. Frameworks (voluntary guidance)

| Framework | Use it for |
|---|---|
| **NIST Cybersecurity Framework (CSF) 2.0** | Organising a security programme: **Govern, Identify, Protect, Detect, Respond, Recover**; common language with executives |
| **NIST SP 800-53 Rev 5** | Detailed control catalogue (the basis of FedRAMP and FISMA) |
| **NIST SP 800-218 (SSDF)** | Secure Software Development Framework; US federal software suppliers attest to it |
| **CIS Critical Security Controls v8.1** | A prioritised list of 18 controls, with Implementation Groups (IG1 for small organisations) |
| **CIS Benchmarks** | Configuration hardening for specific systems ([Linux notes](../linux-security/README.md)) |
| **CSA Cloud Controls Matrix (CCM) + CAIQ + STAR** | Cloud security controls and a standard questionnaire; STAR registry for cloud providers |
| **OWASP ASVS / SAMM** | Application security requirements / maturity of a software-security programme |
| **MITRE ATT&CK** | Detection coverage |
| **COBIT** | IT governance (often with SOX) |

---

## 9. How they overlap: build once, comply many

Most standards ask for the same core controls in different words. Mature teams implement one **unified control set**, then map it to
each framework. That's what continuous-compliance tools (Vanta, Drata) and the Secure Controls Framework do.

| Core control | ISO 27001 | SOC 2 | NIST CSF 2.0 | PCI DSS v4 | FedRAMP (800-53) | GDPR |
|---|---|---|---|---|---|---|
| Risk assessment | Clause 6.1, 8.2 | CC3 | ID.RA | 12.3 | RA family | Art. 32, 35 |
| Access control + MFA | 5.15–5.18, 8.5 | CC6.1–6.3 | PR.AA | 7, 8 | AC, IA | Art. 32 |
| Encryption | 8.24 | CC6.1, CC6.7 | PR.DS | 3, 4 | SC | Art. 32 |
| Logging + monitoring | 8.15, 8.16 | CC7.2 | DE.CM | 10 | AU, SI | Art. 32 |
| Vulnerability management | 8.8 | CC7.1 | ID.RA, PR.PS | 6, 11 | RA-5, SI-2 | Art. 32 |
| Secure development | 8.25–8.29 | CC8.1 | PR.PS | 6 | SA | Art. 25 (by design) |
| Incident response | 5.24–5.28 | CC7.3–7.5 | RS | 12.10 | IR | Art. 33–34 |
| Supplier risk | 5.19–5.23 | CC9.2 | GV.SC | 12.8 | SR | Art. 28 |
| Awareness training | 6.3 | CC1.4, CC2.2 | PR.AT | 12.6 | AT | Art. 39 |
| Business continuity | 5.29–5.30 | A1 | RC | 12.10 | CP | Art. 32(1)(c) |

---

## 10. Interview questions
1. A startup's first enterprise customer asks for "SOC 2 or ISO 27001". How do you choose, and how long does it take?
2. What is FedRAMP, and what's the difference between Moderate and High?
3. What does NIS2 change for company management?
4. What are the GDPR breach-notification requirements? How do they compare with NIS2 and the SEC rule?
5. How would you run one security programme that satisfies ISO 27001, SOC 2 and PCI DSS?
6. What's the difference between a framework, a standard and a regulation? One example of each.
7. What does the Cyber Resilience Act mean for a software company's SBOM and vulnerability-handling process?
