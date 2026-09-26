# Privacy and PII Data Protection

← [GRC index](README.md) · Related: [Principle 09 (protect data and secrets)](../principles/09-protect-data-and-secrets.md) · [Standards and regulations](standards-and-regulations.md)

> Checked as of September 2026. Not legal advice: privacy law is detailed and varies by jurisdiction.

## 1. What counts as personal data

| Term | Meaning | Examples |
|---|---|---|
| **PII** (Personally Identifiable Information, US term) | Information that identifies a person, alone or combined with other data | Name, email, phone, address, SSN, passport number, IP address (often), device ID |
| **Personal data** (GDPR term, broader) | **Any** information relating to an identified or identifiable living person | Everything above, plus cookie IDs, location data, pseudonymous IDs you can link back |
| **Special category / sensitive data** (GDPR Art. 9) | Higher-risk data needing a stronger legal basis | Health, biometrics, genetic data, racial/ethnic origin, religion, sexual orientation, political opinions, trade union membership |
| **PHI** (Protected Health Information, HIPAA) | Health information held by covered entities or their business associates | Medical records, insurance claims |
| **Cardholder data** (PCI DSS) | Payment card number (PAN) + name, expiry, service code | See [payments page](payments-atm-edi.md) |

**In our lab:** Juice Shop's assets A1–A10 ([asset inventory](../../threat-models/juice-shop-assets.md)): emails, addresses, phone numbers,
payment cards and photos are personal data; password hashes and security answers are authentication data; data-deletion requests
(A10) are a GDPR obligation built into the app.

## 2. Roles

| Role | GDPR term | Who | Duties |
|---|---|---|---|
| Decides why and how data is processed | **Controller** | E.g. the shop | Legal basis, transparency, rights, security, breach notification |
| Processes on the controller's instructions | **Processor** | E.g. your SaaS/cloud provider | Only follow instructions, security, help the controller, notify breaches to the controller, **Data Processing Agreement (DPA)** (Art. 28) |
| Oversees compliance | **Data Protection Officer (DPO)** | Required for public bodies and large-scale monitoring or sensitive-data processing | Advise, monitor, contact point for regulators |
| Enforces | **Supervisory authority** | National data-protection authority | Investigates, fines |

## 3. The privacy principles (GDPR Art. 5, reflected in most laws)

| Principle | Meaning | Engineering practice |
|---|---|---|
| Lawfulness, fairness, transparency | A legal basis for each use, and people told clearly | Privacy notice; consent records where consent is the basis |
| **Purpose limitation** | Use data only for the stated purpose | Tag datasets with purpose; block reuse without review |
| **Data minimisation** | Collect only what's needed | Don't log full request bodies; drop unused fields |
| Accuracy | Keep data correct | Let users correct their data |
| **Storage limitation** | Delete when no longer needed | Retention periods + automated deletion jobs |
| **Integrity and confidentiality** | Appropriate security | Encryption, access control, logging (the rest of this repo) |
| **Accountability** | Be able to *prove* compliance | Records of processing (Art. 30), DPIAs, audit logs |

**Privacy by design and by default** (Art. 25): the most privacy-friendly setting is the default, and privacy is designed in, not bolted on.

## 4. Individuals' rights

| Right | GDPR | CCPA/CPRA | Engineering impact |
|---|---|---|---|
| Access (a copy of my data) | Art. 15 | Right to know | Must be able to **find all data about one person** across systems |
| Rectification | Art. 16 | Right to correct | Update everywhere, including downstream copies |
| **Erasure** ("right to be forgotten") | Art. 17 | Right to delete | Delete from primary stores, caches, search indexes, analytics; handle backups with a documented approach |
| Portability | Art. 20 | (partly) | Export in a machine-readable format |
| Object / opt out | Art. 21 | Opt out of sale/sharing | Consent and preference flags honoured everywhere |
| Not subject to solely automated decisions | Art. 22 | (regulations on automated decision-making) | Human review paths for significant decisions |

Requests are called **DSARs** (data subject access requests). GDPR generally requires a response **within one month**. Without a data map,
answering them is slow and error-prone, so **know where personal data lives.**

## 5. Assessments and records

| Artefact | When | Contents |
|---|---|---|
| **Record of Processing Activities (RoPA)** | Always (GDPR Art. 30, with limited exceptions) | What data, why, legal basis, recipients, retention, security measures, transfers |
| **Data map / data inventory** | Always (practically) | Which systems hold which personal data, and data flows between them. The DFD from [threat modelling](../principles/02-threat-modeling.md) is a good start |
| **DPIA** (Data Protection Impact Assessment) | Before high-risk processing (large-scale sensitive data, systematic monitoring, new tech such as AI) | Description, necessity, risks to people, mitigations; consult the regulator if high risk remains |
| **TIA** (Transfer Impact Assessment) | Transfers outside the EU/EEA | Legal risk in the destination country + safeguards (SCCs, EU-US Data Privacy Framework certification) |

## 6. Technical controls for PII

| Control | What it does | Example |
|---|---|---|
| **Data classification + tagging** | Label data (public, internal, confidential, restricted/PII) so controls follow it | Asset table in Lab 1.1 |
| **Encryption at rest and in transit** | Protects stolen disks, backups and network traffic | TLS 1.2+, KMS-managed keys, field-level encryption for the most sensitive fields |
| **Pseudonymisation** | Replace identifiers with pseudonyms; re-identification needs separately held information. **Still personal data** under GDPR, but lower risk | Analytics on `user_hash` instead of email |
| **Anonymisation** | Irreversibly remove the link to a person. Truly anonymous data is outside GDPR, but real anonymisation is **hard** (re-identification by combining datasets) | Aggregated statistics with minimum group sizes |
| **Tokenisation** | Replace a value with a random token; the real value lives in a secured vault | Card numbers (PCI), national IDs |
| **Masking / redaction** | Show only part of a value, or hide it in logs | `****-****-****-1234`; log scrubbing |
| **Access control + just-in-time access** | Only people who need PII can see it, only when needed, and it's logged | Least privilege ([Principle 03](../principles/03-least-privilege.md)) |
| **DLP** (Data Loss Prevention) | Detect or block PII leaving through email, uploads, endpoints | Microsoft Purview, cloud DLP APIs |
| **Retention + deletion automation** | Scheduled jobs remove expired data | Tested like backups: prove it deleted |
| **Secure test data** | Never copy production PII into dev/test | Synthetic or masked data |
| **Logging hygiene** | No passwords, tokens or full PII in logs | Structured logging with field allow-lists |

**Watch out in engineering:** PII leaks most often through **logs**, **analytics and third-party scripts**, **error reports** (stack traces with
request bodies), **backups**, **test databases copied from production**, and now **prompts sent to AI services** ([Principle 13](../principles/13-ai-era-security.md)).

## 7. Breach notification timelines (quick reference)

| Regime | Notify whom | Deadline |
|---|---|---|
| **GDPR** | Supervisory authority (and individuals if high risk) | **72 hours** after becoming aware (authority); individuals "without undue delay" |
| **NIS2** | National CSIRT / authority | Early warning **24 h**, notification **72 h**, final report **1 month** |
| **DORA** | Financial regulator | Initial notification within hours of classifying a major incident, then intermediate and final reports |
| **HIPAA** | Individuals, HHS, sometimes media | Without unreasonable delay, **no later than 60 days** |
| **SEC** (US public companies) | Investors (Form 8-K) | **4 business days** after determining the incident is material |
| **US states** | Residents, sometimes attorneys general | Varies by state (often 30–60 days, or "most expedient time possible") |
| **PCI DSS** | Card brands and acquirer | Per brand rules; immediately upon suspicion |
| **India CERT-In** | CERT-In | **6 hours** for listed incident types |

**Engineering takeaway:** you can't meet 24–72 hour deadlines without logging, a data map, and an incident process prepared
**before** the incident ([Principle 12](../principles/12-assume-breach.md)).

## 8. Hands-on (in this lab)
1. From the [asset inventory](../../threat-models/juice-shop-assets.md), build a mini **RoPA** for Juice Shop: data, purpose, legal basis, retention.
2. Answer a DSAR for your test user: find **every** table and file holding their data (`tmp/juice-shop/models/`, `uploads/`, logs). How long would this take in production?
3. Check what personal data appears in the app's **access logs** (F-014: they're also public!). What should be masked?
4. Draft a DPIA outline for adding the LLM chatbot with access to order history (Principle 13).

## Interview questions
1. What's the difference between pseudonymisation and anonymisation? Why does it matter under GDPR?
2. A user asks you to delete all their data. What's hard about doing that in a microservices system with backups?
3. When is a DPIA required, and what's in it?
4. Controller vs processor: which is a SaaS company, and what contracts are needed?
5. How would you stop PII from ending up in logs?
6. Compare the breach-notification deadlines of GDPR, NIS2 and HIPAA.
