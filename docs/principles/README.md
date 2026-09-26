# Security Principles, Each With Its Labs

This is the backbone of the repo. **Start here and work top to bottom.** Every principle page has the same parts:

1. **In plain words**: what the principle means
2. **Why it matters**: a real, public breach where it was missing
3. **In our lab**: what we actually found in Juice Shop (from the [finding register](../../findings/README.md))
4. **Hands-on labs**: step-by-step exercises that apply the principle
5. **Best-practice checklist**: what a security engineer checks for at work
6. **Interview questions**

New to the field? Do the [baby steps](../basics/README.md) first. They cover the fundamentals these pages assume.

## The principles, in learning order

| # | Principle | The question it answers | Labs | Role focus |
|---|---|---|---|---|
| 00 | [Lab foundation](../labs/lab-00-foundation.md) | What are we running, and what does it expose? | 0 | All |
| 01 | [CIA triad & risk](01-cia-triad-and-risk.md) | What are we protecting, and how bad is a failure? | 1.1–1.2 | All |
| 02 | [Threat modelling](02-threat-modeling.md) | What can go wrong, before we build it? | 2.1–2.3 | Security Eng, AppSec |
| 03 | [Least privilege](03-least-privilege.md) | Does everything have only the access it needs? | 3.1–3.3 | DevSecOps, Cloud Sec |
| 04 | [Defence in depth](04-defense-in-depth.md) | If one control fails, what stops the attacker next? | 4.1–4.3 | DevSecOps, Security Eng |
| 05 | [Minimise attack surface](05-attack-surface-reduction.md) | What can we remove, close or hide? | 5.1–5.3 | All |
| 06 | [Secure defaults, fail securely](06-secure-defaults.md) | Is the out-of-the-box state safe? | 6.1–6.2 | DevSecOps, AppSec |
| 07 | [Never trust input](07-never-trust-input.md) | Can untrusted data change what our code does? | 7.1–7.3 | AppSec |
| 08 | [Identity & access](08-identity-and-access.md) | Who are you, and what are you allowed to do? | 8.1–8.3 | AppSec, Security Eng |
| 09 | [Protect data & secrets](09-protect-data-and-secrets.md) | Is sensitive data safe at rest, in transit and in Git? | 9.1–9.3 | DevSecOps, Security Eng |
| 10 | [Supply-chain integrity](10-supply-chain-integrity.md) | Do we know and trust everything we ship? | 10.1–10.3 | DevSecOps |
| 11 | [Shift left: security as code](11-shift-left-automation.md) | Are controls enforced automatically on every change? | 11.1–11.3 | DevSecOps |
| 12 | [Assume breach: detect & respond](12-assume-breach.md) | When prevention fails, do we notice and recover? | 12.1–12.3 | SecOps, Security Eng |
| 13 | [Security in the AI era](13-ai-era-security.md) | Are our AI features safe, and are we ready for AI-powered attackers? | 13.1–13.5 | All (fast-growing) |

## How the principles fit together

```
        01 CIA + risk ─── decides what matters and how much
              │
        02 Threat model ── finds where it can go wrong
              │
   ┌──────────┼───────────────┬───────────────────┐
   ▼          ▼               ▼                   ▼
 Design     Code            Build/ship          Run
 03 Least   07 Input        10 Supply chain     04 Defence in depth
    privilege  validation   11 Shift left       12 Detect & respond
 05 Attack  08 Identity        (CI gates)
    surface 09 Data/secrets
 06 Secure
    defaults
              │
              ▼
   Findings → fixes → gates that stop regressions → back to 02

   13 AI era: the same principles applied to LLM features, AI-driven attacks and AI-assisted defence
```

## Glossary

The short list is below. The full glossary of terms and tools is in [GLOSSARY.md](../GLOSSARY.md).

| Term | Meaning |
|---|---|
| **Asset** | Something of value: data, a service, credentials, reputation |
| **Threat** | Someone or something that could cause harm (an attacker, an insider, a mistake) |
| **Vulnerability** | A weakness a threat could use |
| **Risk** | Likelihood × impact of a threat using a vulnerability against an asset |
| **Control** | A measure that reduces risk: preventive, detective or corrective |
| **CVE / CVSS / CWE** | A public vulnerability ID / its severity score (0–10) / the weakness category it belongs to |
| **SAST / DAST / SCA** | Static code analysis / testing the running app / scanning third-party dependencies |
| **SBOM** | Software Bill of Materials: the list of every component in what you ship |
| **Zero trust** | Never trust based on network location; verify every request |
| **Blast radius** | How much damage one compromised component can do |

## Further reading
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) and [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- Saltzer & Schroeder, [The Protection of Information in Computer Systems](https://www.cs.virginia.edu/~evans/cs551/saltzer/) (1975), where most of these principles come from
- [NIST SP 800-160](https://csrc.nist.gov/pubs/sp/800/160/v1/r1/final): systems security engineering
- [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/) and [MITRE ATLAS](https://atlas.mitre.org/)
- [Kubernetes security checklist](https://kubernetes.io/docs/concepts/security/security-checklist/)
