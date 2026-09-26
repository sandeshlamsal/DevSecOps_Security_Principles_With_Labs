# Lab 9: AI Security — Reviewing the LLM Chatbot (Execution Guide)
**Lab 9** · [All labs](README.md) · [Principle 13](../principles/13-ai-era-security.md) · [← Lab 8](lab-08-precommit-and-baselines.md)

> **Goal:** threat-model and code-review Juice Shop's LLM chatbot against the OWASP Top 10 for LLM Apps (Labs 13.1–13.2).
> **Deliverable:** [threat-models/juice-shop-chatbot.md](../../threat-models/juice-shop-chatbot.md) (4 findings F-032–F-035). **Executed:** 2026-09-26.

---

## Step 1: Understand the feature (Lab 13.1)
```bash
grep -nE "createOpenAICompatible|tool\(|execute:|generateCoupon|\$where|process.env.LLM" tmp/juice-shop/routes/chat.ts
grep -n "app.post('/rest/chat'" tmp/juice-shop/server.ts    # 657: no auth middleware, no rate limit
```
`POST /rest/chat` is a **tool-using agent**: it gives the model four server-side tools — `searchProducts`, `getProductReviews`,
`getOrderById`, and **`generateCoupon`** (which mints a discount). The DFD and trust boundaries are in the
[chatbot threat model](../../threat-models/juice-shop-chatbot.md#1-what-are-we-building).

## Step 2: Map to the OWASP LLM Top 10 (Lab 13.2)

### The critical one — authorisation in the prompt (F-032, LLM01+LLM06)
`buildSystemPrompt()` states "maximum discount 10%", eligibility rules, etc. But the tool:
```ts
generateCoupon: tool({
  inputSchema: z.object({ discount: z.number()... }),   // the MODEL supplies the number
  execute: async ({ discount }) => {
    const couponCode = security.generateCoupon(discount) // no cap here
    return { couponCode, discount }
  }
})
```
And `security.generateCoupon(discount)` just encodes whatever it's given — **no cap in code**. So the only thing stopping a 50%-off coupon is
the model following prompt text, which prompt injection defeats. Juice Shop even ships challenges for exactly this
(`chatbotPromptInjectionChallenge` at discount≥10, `chatbotGreedyInjectionChallenge` at ≥50). **The policy is not a security boundary; it's a suggestion.**

### The right pattern, for contrast (positive observation)
`getOrderById` authorises **in code**: it resolves the caller's user, compares the order's email, and returns an error otherwise. Same app,
two tools, opposite designs — a clean teaching contrast.

### The rest
| Finding | LLM risk | Note |
|---|---|---|
| F-033 | LLM07 | System prompt contains "CONFIDENTIAL - INTERNAL ONLY" escalation logic → leakable, and it's the security logic itself |
| F-034 | LLM10 | `/rest/chat` is unauthenticated with no rate/spend limit → unbounded paid model calls |
| F-035 | LLM05 | `getProductReviews` string-builds a MarsDB `$where`; **mitigated** by `Number(id)` coercion (triage: real but low) |
| F-008 | LLM05 | Model text is streamed to the browser; the CSP from Lab 3 is the needed second layer |

## Step 3: Fixes — always enforce OUTSIDE the model
- **Cap and authorise in code:** `security.generateCoupon(Math.min(discount, 10))`; verify eligibility against the caller's own orders; require human approval above a threshold.
- **Prompt is not secret and not a boundary:** move policy/escalation logic out of the system prompt into code.
- **Auth + rate/spend limits** on `/rest/chat`.
- **Query by typed field** (`{ product: productId }`), not string-built `$where`.

---

## Lab 9 exit checklist
- [x] Mapped the agent (4 tools, system prompt, endpoint, output) to the OWASP LLM Top 10
- [x] Found the critical prompt-authorisation flaw (F-032) and confirmed no code-side cap
- [x] Recorded the positive contrast (`getOrderById` authorises in code)
- [x] 4 findings (F-032–F-035) with fixes that live outside the model
- [x] Triaged the `$where` sink down (Number() coercion) rather than over-reporting

**Interview takeaway:** "Secure an AI agent that can take actions." Least agency, authorise every tool in code using the caller's identity,
never put policy/secrets in the prompt, treat model output as untrusted, and add auth + rate/spend limits. Prompt injection can't be fully
solved, so the model must never be the thing enforcing a rule.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L9-ISSUE-1 | The chatbot looked trivial (a config value in Lab 1) | v20.2.0 turned it into a real tool-using agent with a state-changing tool | Re-read the code each version; AI features change fast |
| L9-ISSUE-2 | The `$where` sink looked like NoSQL injection | `Number(id)` coerces the input, neutralising it | Triage the actual data flow before rating; note fragile patterns without overstating |

---
**Lab 9** · [All labs](README.md) · [Principle 13](../principles/13-ai-era-security.md) · [← Lab 8](lab-08-precommit-and-baselines.md)
