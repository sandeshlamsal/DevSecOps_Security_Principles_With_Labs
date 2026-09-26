# 01: The CIA Triad and Risk

> "Security is not about making things impossible to attack. It's about making the risk acceptable."

## In plain words
Everything in security protects one or more of three properties:

| Property | Question | Broken when… | Juice Shop example |
|---|---|---|---|
| **Confidentiality** | Can only the right people *see* it? | Data leaks | Another customer's order history is readable |
| **Integrity** | Can only the right people *change* it? | Data is tampered with | A product price or a review is modified by a stranger |
| **Availability** | Is it there when needed? | Service is down or too slow | The shop crashes under a flood of requests |

**Risk** is how we decide what to fix first:

```
Risk = Likelihood (how easy + how exposed) × Impact (how bad for C, I or A)
```

A critical-severity bug on an internal, unreachable test box can be lower risk than a medium bug on the public login page.
Severity describes the bug; **risk describes the bug in *your* context.**

## Why it matters
- **Equifax (2017), confidentiality:** a known, patched web-framework vulnerability was left unpatched on an internet-facing
  system for about two months. Personal data of roughly 147 million people leaked.
- **NotPetya (2017), integrity and availability:** malware spread through a compromised software update and wiped systems
  worldwide, halting shipping and manufacturing for weeks.

## In our lab
Phase 0 found 9 weaknesses before any testing ([finding register](../../findings/README.md)). Each is rated by risk, not by
how scary it sounds. For example, F-005 (a public `/ftp` directory listing) is **High** because it's reachable with no login
and exposes internal documents (confidentiality).

## Hands-on labs

### Lab 1.1: Asset inventory and CIA rating ✅ ([execution guide](../labs/lab-01-cia-and-risk.md))
1. `make open`, then browse the shop as a normal customer: register, add to basket, check out, write a review.
2. List every **data asset** you touched (accounts, passwords, addresses, payment cards, orders, reviews, product catalogue).
3. For each asset, rate C, I and A as High/Medium/Low. Payment cards: C=High. Product catalogue: C=Low, I=High.
4. Record it in `threat-models/juice-shop-assets.md`. Lab 2 builds on this table.

### Lab 1.2: Risk-rate real findings ✅ (done in [Lab 0](../labs/lab-00-foundation.md))
1. Read the Phase 0 findings in the [finding register](../../findings/README.md).
2. For each one, write down which CIA property it threatens, its likelihood and its impact.
3. Compare your ratings with ours and note where you disagree and why. Disagreement is normal; the *reasoning* is what matters in interviews.

## Best-practice checklist
- [ ] There is an asset inventory, and each asset has a data classification (public, internal, confidential, restricted)
- [ ] Findings are prioritised by risk (context), not by scanner severity alone
- [ ] Every accepted risk has an owner, a reason and an expiry date
- [ ] Availability is treated as a security property (rate limits, quotas, DoS protection)

## Interview questions
1. Explain the CIA triad with an example of each being broken.
2. What is the difference between a threat, a vulnerability and a risk?
3. A scanner reports a CVSS 9.8 in a library. How do you decide how urgently to fix it?
4. When would you *accept* a risk instead of fixing it, and what must be recorded?
5. What does the AAA model (authentication, authorisation, accounting) add to CIA?
