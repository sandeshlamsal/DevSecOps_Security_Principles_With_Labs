# 13: Security in the AI Era

> "AI is a new attack surface, a new attacker tool and a new defender tool, all at once. The old principles still apply."

This principle has three parts, because security roles now meet AI in three ways:

| Part | The question | Who owns it at work |
|---|---|---|
| **A. Securing AI systems** | Is our own LLM feature or AI agent safe? | AppSec, Security Engineering |
| **B. Defending against AI-driven attacks** | Are our people and processes ready for AI-powered attackers? | Security Ops, awareness, IAM |
| **C. Using AI for defence, safely** | Can AI help our team without creating new risk? | Every security role |

---

## A. Securing AI systems (LLM apps and agents)

### In plain words
An LLM **can't reliably tell instructions from data**. Any text it reads (a user message, a web page, a PDF, an email, a
tool result) can contain instructions it might follow. That is **prompt injection**, and it is the "never trust input"
problem ([07](07-never-trust-input.md)) in a new form, except there is no equivalent of a parameterised query that fully fixes it.
So the design principle is: **limit what the model can do, and treat its output as untrusted.**

The [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/llm-top-10/), mapped to the principles you already know:

| OWASP LLM risk | What it means | Classic principle it maps to |
|---|---|---|
| LLM01 Prompt injection | Direct or indirect (hidden in content the model reads) instructions override intended behaviour | [07 Never trust input](07-never-trust-input.md) |
| LLM02 Sensitive information disclosure | The model reveals secrets, PII or other users' data | [09 Protect data](09-protect-data-and-secrets.md) |
| LLM03 Supply chain | Untrusted models, weights, datasets or plugins | [10 Supply chain](10-supply-chain-integrity.md) |
| LLM04 Data and model poisoning | Training or fine-tuning data is manipulated | [10 Supply chain](10-supply-chain-integrity.md), integrity |
| LLM05 Improper output handling | Model output goes into HTML, SQL or a shell without encoding | [07 Never trust input](07-never-trust-input.md) |
| LLM06 Excessive agency | An agent has more tools or permissions than its task needs | [03 Least privilege](03-least-privilege.md) |
| LLM07 System prompt leakage | Secrets or security logic placed in the prompt are exposed | [09 Protect secrets](09-protect-data-and-secrets.md) |
| LLM08 Vector and embedding weaknesses | RAG stores leak across tenants or can be poisoned | [08 Access control](08-identity-and-access.md) |
| LLM09 Misinformation | Confident, wrong output is trusted by users or code | [06 Fail securely](06-secure-defaults.md) |
| LLM10 Unbounded consumption | Cost or availability attacks through expensive requests | [01 Availability](01-cia-triad-and-risk.md) |

**Design controls that work:**
- **Least agency:** give agents the minimum tools, read-only by default, scoped credentials, and **human approval for
  irreversible actions** (sending, paying, deleting, deploying).
- **Never put secrets or authorisation logic in the prompt.** Enforce authorisation in code, outside the model, using the
  *end user's* permissions and not the service's.
- **Treat model output as untrusted input** to anything downstream: encode it, validate it against a schema, and allow-list tool arguments.
- **Separate trusted and untrusted content**, and be most careful when one agent both reads untrusted content *and* has
  powerful tools. That combination is where indirect prompt injection causes real damage.
- **Log prompts, tool calls and outputs** (with PII controls), set rate and spend limits, and red-team the feature before release.

### Why it matters
Researchers have repeatedly shown indirect prompt injection against AI assistants connected to email, documents and web
browsing. For example, instructions hidden in a web page or shared document caused an assistant to leak data from the
user's other content. The consistent lesson: an assistant that reads untrusted content and can take actions needs hard limits
outside the model.

---

## B. Defending against AI-driven attacks

| AI-enabled threat | What changed | Controls |
|---|---|---|
| **Phishing at scale** | Fluent, personalised lures in any language; spelling mistakes are no longer a signal | Phishing-resistant MFA (FIDO2/passkeys), email authentication (SPF, DKIM, DMARC), reporting culture |
| **Deepfake voice and video** | Real cases of staff wiring money after video calls with deepfaked executives (e.g. a reported ~US$25M loss in Hong Kong, 2024) | Out-of-band verification for payments and credential resets; "no exceptions for urgency" policy |
| **Faster exploitation** | Less time between a vulnerability being disclosed and being exploited | Fast patching (see [10](10-supply-chain-integrity.md)), asset inventory, virtual patching at the edge |
| **Help-desk social engineering** | Convincing voice clones and scripted pretexts to reset MFA | Strong identity proofing for resets, callback to a known number, manager approval |
| **AI-generated code** | More code, faster, sometimes with insecure patterns or invented ("hallucinated") package names that attackers then register | SAST and SCA gates ([11](11-shift-left-automation.md)), dependency allow-lists, human review |

The pattern: **AI makes attacks cheaper and more convincing, so controls must not depend on humans spotting fakes.**
Prefer controls that hold even if the person is fooled: phishing-resistant MFA, verification through a separate channel, and least privilege.

---

## C. Using AI for defence, safely

AI is genuinely useful to security teams: summarising alerts and logs, explaining unfamiliar code, drafting detection rules,
triaging SAST/SCA results, and writing threat-model first drafts. Use it the way you'd use a fast junior analyst:

- **Verify before acting.** AI output is a lead, not evidence. Confirm against the raw logs and code.
- **Mind the data.** Don't paste secrets, customer data or incident details into tools your organisation hasn't approved.
- **Keep humans accountable** for decisions: closing an incident, accepting a risk, merging a fix.
- **Measure it.** Track false positives and misses, as you would for any detection tool.

---

## In our lab
- Juice Shop v20 ships an **LLM chatbot feature**; `/metrics` already exposes `juiceshop_llm_input_tokens_total`. It is the
  "our own AI feature" to threat-model and review.
- This repo itself was scaffolded with an AI coding assistant. Every generated command and claim was checked against real
  output in the lab guides. That's practice C.

## Hands-on labs

### Lab 13.1: Threat-model the AI feature ⏳
1. Read how the chatbot is wired in the source (`tmp/juice-shop`, search for the LLM client and the chatbot route).
2. Draw its data flow: user → API → model provider → tools/data it can reach → output back to the browser.
3. Walk each flow through the OWASP LLM Top 10 table above, not only STRIDE. Record threats in `threat-models/`.

### Lab 13.2: Review the integration code ⏳
Answer from the code, with file and line references:
1. Is the model's output inserted into the page safely (LLM05)?
2. What data and actions can the model reach, and whose permissions are used (LLM06, LLM08)?
3. Are there secrets or business rules in the system prompt (LLM07)?
4. Are there rate or spend limits (LLM10)?
Write a finding for each gap, with a fix that works **outside** the model.

### Lab 13.3: Build an AI security test plan ⏳
Write test cases (not a one-off hack) for your own app's AI feature: direct injection, indirect injection through content the
bot reads, output-encoding checks, and a cost-limit check. Look at open-source evaluation tools such as
[garak](https://github.com/NVIDIA/garak) or [promptfoo](https://www.promptfoo.dev/) for running them repeatably in CI, and
explain which risks tests can and can't prove are fixed.

### Lab 13.4: Anti-deepfake payment process ⏳
Write a one-page process for a finance team: which requests need out-of-band verification, how to verify, and what to do when
someone senior insists it's urgent. Then list which technical controls back it up.

### Lab 13.5: AI-assisted triage, verified ⏳
Give an AI assistant 20 Semgrep findings from Lab 7.1 and ask it to classify them as true or false positive. Compare with your own
manual triage. Record its accuracy and where it was confidently wrong. That number is your evidence for how far to trust it.

## Best-practice checklist
- [ ] AI features have a threat model covering the OWASP LLM Top 10
- [ ] Agents have least agency: scoped tools and credentials, human approval for irreversible actions
- [ ] Model output is treated as untrusted; authorisation is enforced in code, never in the prompt
- [ ] Prompts, tool calls and costs are logged and rate-limited
- [ ] Models, datasets and AI packages go through the same supply-chain checks as other dependencies
- [ ] Payment and credential-reset processes don't rely on recognising a voice or face
- [ ] There's an approved-AI-tools policy that says what data may be shared with which tools

## Interview questions
1. What is prompt injection? Why can't it be fully solved like SQL injection?
2. Direct vs indirect prompt injection: give an example of each.
3. How would you secure an AI agent that can read email and send messages?
4. Walk me through three items from the OWASP Top 10 for LLM Applications and the controls for each.
5. How has AI changed phishing, and which controls still work when the email is perfect?
6. Your team wants to use an AI assistant for alert triage. What guardrails would you put in place?
7. What is "slopsquatting" (hallucinated package names), and how does your pipeline defend against it?

## Further reading
- [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/)
- [MITRE ATLAS](https://atlas.mitre.org/): ATT&CK-style knowledge base for attacks on AI systems
- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)
