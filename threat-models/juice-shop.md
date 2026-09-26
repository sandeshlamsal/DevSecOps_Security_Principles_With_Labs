# Threat Model: OWASP Juice Shop

- **Lab:** [2.1–2.2](../docs/principles/02-threat-modeling.md) · **Date:** 2026-09-26 · **App version:** 20.2.0
- **Method:** Shostack's 4 questions + **STRIDE** per element. Built from a source review of the pinned code (routes, `server.ts`,
  data layer) and confirmed against the running app. Execution record: [lab-02](../docs/labs/lab-02-threat-modeling.md).
- **Assets:** see the [asset inventory](juice-shop-assets.md). **Findings:** [register](../findings/README.md).

## 1. What are we building?

A single-container web shop: an Angular browser app, a Node.js/Express API (175 route registrations), a SQLite relational database, a
MarsDB document store (reviews and orders), an on-disk file area, a WebSocket channel, and an optional LLM chatbot. It also makes
**outbound** calls: fetching a URL for profile-image upload, and (when configured) the LLM endpoint.

```mermaid
flowchart TB
  subgraph browser["Browser (untrusted client)"]
    ng[Angular app + JWT in localStorage]
  end
  subgraph tb["Trust boundary: the pod (one container)"]
    api[Express API<br/>175 routes]
    subgraph data["Data stores"]
      sql[(SQLite<br/>users, cards, addresses, wallets)]
      mars[(MarsDB<br/>reviews, orders)]
      files[/ftp, uploads, encryptionkeys,<br/>infrastructure, logs/]
    end
    ws[WebSocket]
    parsers[File parsers:<br/>zip, XML, YAML, JS eval]
  end
  ext[(External: image URL host,<br/>LLM endpoint)]
  attacker((Anonymous<br/>internet)) -.->|no NetworkPolicy| api
  ng -->|HTTPS/JSON + JWT| api
  ng <-->|events| ws
  api --> sql
  api --> mars
  api --> files
  api --> parsers
  api -->|fetch(imageUrl), LLM| ext
  ng -->|"/ftp /metrics /support/logs /encryptionkeys /infrastructure"| files
```

**Trust boundaries:** (1) browser ↔ API (every request is attacker-controlled), (2) anonymous internet ↔ the pod (there's **no
NetworkPolicy**, F-003), (3) the pod ↔ external hosts it calls out to, (4) untrusted uploaded content ↔ the parsers that process it.

## 2. What can go wrong? (STRIDE)

Risk = likelihood × impact, rated for this deployment ([Principle 01](../docs/principles/01-cia-triad-and-risk.md)).

| ID | Element / flow | STRIDE | Threat | Risk | Finding / control |
|---|---|---|---|---|---|
| T-01 | JWT signing | **S**poofing | The signing key is in public source, so a token can be forged for any user, including admin | **Critical** | F-010 → rotate to a Secret (plan C2) |
| T-02 | Login | Spoofing | No rate limit on `/rest/user/login`: credential stuffing / brute force | High | New: add rate limit (like reset-password already has) |
| T-03 | OAuth login | Spoofing | The account password is **derived from the email** by a reversible, client-side transformation, so knowing an email is enough to know the password | High | New finding F-025 |
| T-04 | Product search / login SQL | **T**ampering | Untrusted input concatenated into SQL (`search.ts`, `login.ts`) | High | F-016 → parameterise (plan C3) |
| T-05 | Orders / baskets / `/api/Users/:id` | Tampering / **E**oP | Object-level authorisation gaps let a user read or change another user's records (IDOR) | High | Lab 8.2 |
| T-06 | Wallet / coupons | Tampering | Manipulating balances or discounts = direct financial loss (integrity of A5/A6) | Medium | Lab 8.2 |
| T-07 | Reviews / feedback (MarsDB) | Tampering | NoSQL injection or stored XSS via document queries and rendered content | High | F-008 (no CSP) + input validation |
| T-08 | Access logs | **R**epudiation | Logs are web-served (F-014) and not tamper-proofed: an attacker can read and (with file write) alter history | High | F-014 → stop serving logs (plan C1), append-only/off-host |
| T-09 | `/ftp`, `/encryptionkeys`, `/infrastructure`, `/support/logs` | **I**nfo disclosure | Public listings expose internal docs, **a private key**, and logs | Critical/High | F-005, F-013, F-014, F-015 → block + rotate (B1, C1, C2) |
| T-10 | `/metrics` | Info disclosure | Prometheus metrics, incl. LLM usage, served with no auth | Low | F-006 |
| T-11 | Change-password | Info disclosure | Passwords passed in the URL **query string** (GET), so they land in access logs in clear — which are also public (T-08) | High | New finding F-026 |
| T-12 | Error responses | Info disclosure | Stack traces / versions leak internals | Medium | F-... (Lab 6.2) |
| T-13 | Profile-image-by-URL | Info disclosure / **E**oP | The server fetches an attacker-supplied URL (**SSRF**): can reach internal services / cloud metadata | High | New finding F-027; the code even flags an `abused_ssrf_bug` |
| T-14 | B2B order endpoint | **E**levation of privilege | Order data is passed to a JavaScript `eval` in a `vm` sandbox: sandbox escape → code execution | High | New finding F-028; keep dependencies patched, remove eval |
| T-15 | XML upload | Info disclosure / **D**oS | XML parsed with entity expansion enabled (`XML_PARSE_NOENT`, `DTDLOAD`): **XXE** (file read, SSRF) and billion-laughs DoS | High | New finding F-029 |
| T-16 | Zip upload | Tampering | Path traversal on extraction (`../`) can write outside the target dir (zip-slip); the code checks, so verify the check holds | Medium | F-018 relates; verify in Lab 7.1 |
| T-17 | YAML upload | DoS | YAML parsed in a `vm` with a 2s timeout: malicious YAML can still exhaust CPU/memory | Medium | New; resource limits (F-021) help |
| T-18 | Any endpoint | **D**enial of service | Most endpoints have no rate limit; no pod CPU limit (F-021) | Medium | Rate limiting + resource limits |
| T-19 | Container / pod | Elevation of privilege | No securityContext, default SA token mounted, flat network: an app compromise escalates and moves laterally | Medium | F-001–F-004 → harden (plan A1–A3) |
| T-20 | Supply chain | Tampering | 53 High/Critical dependency CVEs; unsigned, tag-pinned image | High | F-017, F-009 → scan/sign/pin (Phase 3) |
| T-21 | LLM chatbot | Info disclosure / EoP | When wired to a model: prompt injection, data leakage, excessive agency | (future) | [Principle 13](../docs/principles/13-ai-era-security.md) |

## 3. What are we going to do about it?

Every High/Critical threat maps to a finding and a remediation step in [REMEDIATION.md](../findings/REMEDIATION.md). New threats found by
this model (T-02, T-03, T-11, T-13, T-14, T-15) were added to the [finding register](../findings/README.md) as F-025–F-029.
Priority order is unchanged: rotate exposed secrets and block exposed paths first, then fix injection and access control, then harden the platform.

## 4. Did we do a good job?

- **Covered:** every trust boundary, all six STRIDE letters, and each of the 175-route API's main capabilities (auth, data, uploads, B2B, outbound calls).
- **Assumptions:** the LLM chatbot is not connected in this deployment (T-21 is future work); the review is of v20.2.0 source.
- **Revisit when:** the chatbot gets tools/data access, a payment provider is added, or the app is exposed beyond localhost.
- **Lab 2.3 (threat-model a change):** adding "log in with Google" — see the [lab guide](../docs/labs/lab-02-threat-modeling.md#lab-23-threat-model-a-change).
