# 02: Threat Modelling

> "Think like an attacker, early, when changes are cheap."

## In plain words
Threat modelling is a structured conversation about a design, built on four questions (Adam Shostack's framework):

1. **What are we building?** Draw a data-flow diagram (DFD): users, processes, data stores, and the **trust boundaries** between them.
2. **What can go wrong?** Walk every element and data flow through **STRIDE**.
3. **What are we going to do about it?** Mitigate, eliminate, transfer or accept each threat.
4. **Did we do a good job?** Review it, and update it when the design changes.

| STRIDE | Threat | Property violated | Typical control |
|---|---|---|---|
| **S**poofing | Pretending to be someone else | Authentication | MFA, strong sessions |
| **T**ampering | Changing data or code | Integrity | Input validation, signing, access control |
| **R**epudiation | Denying you did something | Non-repudiation | Audit logs |
| **I**nformation disclosure | Seeing what you shouldn't | Confidentiality | Encryption, authorisation |
| **D**enial of service | Making it unavailable | Availability | Rate limits, quotas |
| **E**levation of privilege | Gaining rights you shouldn't have | Authorisation | Least privilege, authz checks |

## Why it matters
"Insecure design" became its own category (A04) in the OWASP Top 10 in 2021. Some flaws can't be fixed by better
code, because the design itself is wrong. For example, a password-reset flow that relies on a guessable security question.

## In our lab
Juice Shop has a browser (Angular), a Node.js API, a SQLite database, a file area (`/ftp`) and a metrics endpoint, all behind
one port. Phase 0 showed that the trust boundary between "anonymous internet" and "internal files/metrics" is **missing**
(findings F-005, F-006).

## Hands-on labs

### Lab 2.1: Draw the data-flow diagram ✅ ([execution guide](../labs/lab-02-threat-modeling.md))
1. Using the app, the network tab of browser DevTools and `/api` responses, identify the components and data flows.
2. Draw the DFD as a Mermaid diagram in `threat-models/juice-shop.md` (use the [template](../templates/threat-model.md)).
3. Mark trust boundaries: browser ↔ API, API ↔ database, cluster ↔ your laptop.

### Lab 2.2: STRIDE the login and checkout flows ✅ ([threat model](../../threat-models/juice-shop.md))
1. For each element crossing a trust boundary, ask each STRIDE question.
2. Aim for 15+ threats. Rate each one with the risk method from [01](01-cia-triad-and-risk.md).
3. Link each threat to an existing finding, or open a new one in [findings/](../../findings/README.md).

### Lab 2.3: Threat-model a change ⏳
Pretend the team wants to add "log in with Google". Threat-model **only the change**, in 30 minutes. This is how threat
modelling works day to day in real teams: small and frequent, not one giant document.

## Best-practice checklist
- [ ] New features with new data flows or trust boundaries get a lightweight threat model before build
- [ ] Threat models live next to the code, in version control, and are updated with the design
- [ ] Every high-risk threat maps to a control **and** to a test that proves the control works
- [ ] Developers take part, so it's a conversation and not an audit

## Interview questions
1. Walk me through how you would threat-model a new payments API.
2. What is a trust boundary? Give two examples from a typical web app.
3. Explain STRIDE. Which letter does "a user reads another user's invoice" belong to?
4. How do you keep threat modelling from slowing teams down?
5. STRIDE vs PASTA vs attack trees: when would you use each?
