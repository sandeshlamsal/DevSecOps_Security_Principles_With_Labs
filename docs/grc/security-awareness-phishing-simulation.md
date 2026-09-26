# Security Awareness and Phishing Simulations

**How companies run those "test" phishing emails.** A phishing simulation is an **authorised, internal training programme**. The goal
is not to catch people out. It's to measure and improve how well staff **spot and report** real phishing. People are part of the
attack surface ([Principle 13, part B](../principles/13-ai-era-security.md#b-defending-against-ai-driven-attacks)), and
frameworks like ISO 27001 (control 6.3), SOC 2, PCI DSS (requirement 12.6) and NIST CSF require security awareness training.

← [GRC index](README.md)

---

## 1. Who runs it, and the rules first

| Step | What happens | Why |
|---|---|---|
| **Written approval** | Security leadership signs off, with HR, Legal and often the works council/unions (required in parts of Europe) | Simulated deception of employees needs a clear mandate and privacy review |
| **Scope and rules of engagement** | Who is in scope, frequency, which themes are off-limits, how data is used | Avoid harm and keep trust |
| **Privacy notice** | Staff are told (in policy, not per email) that simulations happen and what is recorded | GDPR/transparency; results are personal data |
| **Technical allow-listing** | Mail gateway and URL-rewriting tools allow the simulation sender, so the test reaches inboxes and "clicks" aren't triggered by security scanners | Otherwise results are meaningless |
| **Help desk briefed** | The service desk knows a campaign is live | Reports are handled correctly |

**Ethics** (widely adopted good practice):
- **No punishment** for clicking. Punishment makes people hide mistakes, and the goal is fast *reporting*.
- **Avoid cruel lures**: fake bonuses, layoffs, health scares, or charity appeals during a real crisis. They damage trust more than they teach.
- **Aggregate reporting** to management (by department), not naming individuals.
- Repeat clickers get **extra coaching**, not public shaming.

## 2. How a campaign works

```mermaid
flowchart LR
  plan[Plan: theme, audience,<br/>difficulty, schedule] --> tpl[Pick template<br/>from the platform library]
  tpl --> send[Send in waves<br/>(randomised times)]
  send --> user{Employee}
  user -->|reports it| rep[Report button<br/>→ thank-you + points]
  user -->|ignores| none[No action]
  user -->|clicks| land[Landing page:<br/>'This was a simulation'<br/>+ 2-min lesson on the cues]
  land --> jit[Just-in-time<br/>micro-training]
  rep --> metrics[Metrics dashboard]
  none --> metrics
  jit --> metrics
  metrics --> next[Adjust next campaign<br/>+ targeted training]
```

**How clicks are tracked:** each recipient gets a **unique link** (a random token in the URL) and sometimes a tracking pixel for opens.
When that link is visited, the platform knows who clicked and when. No real credentials are ever collected: if a simulation shows a
fake login page, it records only *that* something was submitted, and then shows the lesson.

**Difficulty levels**, based on real attacks the organisation actually sees:

| Level | Typical characteristics | What it teaches |
|---|---|---|
| Easy | Generic sender, obvious urgency, mismatched link | Basic cues |
| Medium | Look-alike domain, plausible business context (invoice, shared document, delivery) | Check the real sender and link target |
| Hard | Internal-looking notification, current events, well written (AI makes this easy for real attackers) | Report even when unsure; verify out of band |

Other channels increasingly tested: **SMS (smishing)**, **voice calls (vishing)**, **QR codes (quishing)**, and MFA-fatigue push prompts,
usually only with specific approval.

## 3. Tools

| Tool | Type |
|---|---|
| **Microsoft Defender for Office 365: Attack Simulation Training** | Built into Microsoft 365 (E5 / add-on) |
| **KnowBe4, Proofpoint Security Awareness, Hoxhunt, Cofense** | Commercial platforms with template libraries and training content |
| **GoPhish** | Open source; used by security teams that run their own programme |

## 4. Metrics that matter

| Metric | Why |
|---|---|
| **Report rate** (reported ÷ delivered) | **The most important one.** A high report rate means real attacks get noticed quickly |
| **Time to first report** | How fast the SOC hears about a real campaign |
| Click rate / credential-submission rate | Useful trend, but easy to game with easy templates |
| Repeat-clicker rate | Where coaching helps most |
| Real phishing reported by staff | Proves the programme works outside simulations |

## 5. The cues employees are taught to check

1. **Sender:** the real address, not the display name; look-alike domains (`rn` vs `m`, extra words, different TLD).
2. **Links:** hover to see the real destination before clicking. On mobile, press and hold.
3. **Urgency or fear:** "account closes today", "CEO needs this now".
4. **Unusual requests:** payment changes, gift cards, credentials, MFA codes. **Verify through a known channel** (call the number you already have, not one in the email).
5. **Attachments:** unexpected files, especially macros, archives, HTML files and QR codes.
6. **When unsure, report.** Reporting a real email costs nothing; missing one can cost everything.

## 6. Where this fits for a security engineer

As a DevSecOps or security engineer you usually don't run the campaigns, but you'll often:
- configure the **mail-security side**: SPF, DKIM, DMARC at `p=reject`, and allow-listing for the simulation platform
- integrate the **report button** with the SOC's triage workflow (reported emails are auto-analysed)
- make technical controls **not depend on people**: phishing-resistant MFA (FIDO2/passkeys), conditional access, and least privilege,
  so a single click doesn't become a breach

## Interview questions
1. How would you measure whether security awareness training works?
2. Why is report rate a better metric than click rate?
3. What technical controls reduce the impact when someone does fall for phishing?
4. What ethical and privacy considerations apply to phishing simulations?
5. How has AI changed phishing, and how should simulations adapt?
