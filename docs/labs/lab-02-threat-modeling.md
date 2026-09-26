# Lab 2: Threat Modelling with STRIDE (Execution Guide)
**Lab 2** · [All labs](README.md) · [Principle 02](../principles/02-threat-modeling.md) · [← Lab 1](lab-01-cia-and-risk.md)

> **Goal:** draw Juice Shop's data-flow diagram, walk every element through STRIDE, and turn the threats into findings.
> **Deliverable:** [threat-models/juice-shop.md](../../threat-models/juice-shop.md) (21 threats; 5 new findings F-025–F-029).
> **Time:** about 2 hours. **Executed:** 2026-09-26.

---

## Method

Adam Shostack's four questions: **what are we building → what can go wrong (STRIDE) → what do we do about it → did we do a good job.**
Rather than clicking around, the model was built by **reading the pinned source**, which is how a real design review works and which finds
threats that black-box testing misses (SSRF, eval, XXE).

## Step 1: What are we building? (map the real surface)

```bash
cd tmp/juice-shop
grep -cE "app\.(get|post|put|patch|delete|use)\(" server.ts        # 175 route registrations
grep -rn "new MarsDB.Collection" data/mongodb.ts                    # a 2nd datastore: reviews, orders
grep -nE "multer|handleXmlUpload|handleYamlUpload|handleZipFileUpload|b2bOrder|profileImageUrlUpload" server.ts
grep -rnE "fetch\(|llmApiUrl" routes/*.ts lib/*.ts                   # outbound calls (SSRF surface, LLM)
```
Findings that shaped the diagram: **two** data stores (SQLite + MarsDB), a file area, a WebSocket channel, file **parsers** (zip, XML, YAML,
JS eval) that process untrusted uploads, and **outbound** calls (`fetch(imageUrl)`, the LLM endpoint). The DFD and trust boundaries are in
the [threat model](../../threat-models/juice-shop.md#1-what-are-we-building).

## Step 2: What can go wrong? (STRIDE per element)

Walking each element and flow through the six STRIDE categories produced **21 threats**. Six were confirmed by reading the exact code:

| Threat | Evidence in source |
|---|---|
| T-13 SSRF | `routes/profileImageUrlUpload.ts`: `const url = req.body.imageUrl … await fetch(url)` — and the code even sets `abused_ssrf_bug` |
| T-14 B2B eval | `routes/b2bOrder.ts`: `vm.runInContext('safeEval(orderLinesData)', …)` on request data |
| T-15 XXE | `lib/xml.ts`: parser options include `XML_PARSE_NOENT | XML_PARSE_DTDLOAD` (entity + DTD loading on) |
| T-11 password in URL | `routes/changePassword.ts`: reads `query.current` / `query.new`; `server.ts` logs every request with `morgan('combined')` |
| T-02 no login rate limit | `/rest/user/reset-password` has `rateLimit(...)` but `/rest/user/login` does not |
| T-03 OAuth password | `frontend/.../oauth.component.ts`: password derived reversibly from the email, client-side |

## Step 3: Confirm one end-to-end chain safely (T-11 + T-08)

Passwords in the URL are only a paper risk until you show where they end up. Done on a **throwaway account I created**, on localhost:
```bash
B=http://127.0.0.1:3000; E="lab2-$(date +%s)@example.test"; P='Lab2-Old-Passw0rd!'; N='Lab2-New-Passw0rd!'
curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' \
  -d "{\"email\":\"$E\",\"password\":\"$P\",\"passwordRepeat\":\"$P\",\"securityQuestion\":{\"id\":1},\"securityAnswer\":\"lab\"}" $B/api/Users/   # 201
T=$(curl -s -H 'Content-Type: application/json' -d "{\"email\":\"$E\",\"password\":\"$P\"}" $B/rest/user/login | python3 -c "import json,sys;print(json.load(sys.stdin)['authentication']['token'])")
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $T" -G \
  --data-urlencode "current=$P" --data-urlencode "new=$N" --data-urlencode "repeat=$N" $B/rest/user/change-password   # 200
curl -s "$B/support/logs/access.log.$(date +%F)" | grep change-password | tail -1   # the new password appears in clear in the PUBLIC log
```
Result: the password change succeeded (200) and the new password appears **in clear** in `/support/logs/access.log.…`, which needs no login
to download (F-014). Two medium/low issues (query-string secret + public logs) combine into a **High**. That combination is exactly what
a threat model is for. Confirms **F-026**.

## Step 4: What are we going to do about it?

All 21 threats map to findings and to steps in [REMEDIATION.md](../../findings/REMEDIATION.md). The 5 threats with no prior finding became
**F-025 (OAuth password), F-026 (password in URL→public log), F-027 (SSRF), F-028 (B2B eval), F-029 (XXE)**, all High.

## Lab 2.3: Threat-model a change (log in with Google)

Threat modelling in real teams is small and frequent: model **only the change**, in ~30 minutes.

**Change:** add "Log in with Google" (OAuth 2.0 / OIDC).

| STRIDE | Threat on the change | Control |
|---|---|---|
| Spoofing | Accepting an ID token without verifying its signature, `iss`, `aud` and expiry | Verify the token against Google's JWKS; check `iss`/`aud`; use a vetted library |
| Spoofing | **Don't derive the local password from the email** (the existing F-025 mistake) | No shadow password; link accounts by verified `sub` claim |
| Tampering | CSRF on the OAuth callback | `state` parameter bound to the session; PKCE |
| Info disclosure | Requesting more scopes than needed | Minimal scopes (`openid email`); [least privilege](../principles/03-least-privilege.md) |
| Info disclosure | Open-redirect via the `redirect_uri` | Exact allow-list of redirect URIs |
| Elevation | Auto-provisioning an admin from an email domain | Explicit role mapping; verified email only |
| Repudiation | No audit of federated logins | Log the `sub` and provider for each login |

**Lesson:** the login change re-uses several existing principles (identity, least privilege, secure defaults) and would have caught F-025
*before* it shipped, which is the whole point of modelling a change at design time.

---

## Lab 2 exit checklist
- [x] Data-flow diagram with 4 trust boundaries, built from source
- [x] STRIDE applied to every element: 21 threats, all six letters covered
- [x] 6 threats confirmed against exact code; 1 chain (F-026) confirmed on the running app
- [x] 5 new findings (F-025–F-029) added to the register and mapped to fixes
- [x] A design-time threat model of a proposed change (Lab 2.3)

**Interview takeaway:** "Threat-model this feature." You can walk the four questions, draw a DFD, apply STRIDE, rate by risk, and show
that modelling a *change* (OAuth) catches design flaws like a password derived from an email before they ship.

---

## Issues log

| ID | Symptom | Root cause | Fix / lesson | Verified |
|---|---|---|---|---|
| L2-ISSUE-1 | Reading routes alone, the SSRF, eval and XXE risks weren't obvious | The dangerous behaviour is in helper modules (`lib/xml.ts`, `routes/b2bOrder.ts`), not the route line | Follow each route into the handler and the libraries it calls; STRIDE on **data flows**, not just endpoints | 3 High findings found this way |
| L2-ISSUE-2 | The password-in-URL risk looked "Medium" in isolation | Risk depends on **combinations**: query-string secret (medium) + public, tamperable logs (F-014) = High | Rate chains of threats, not only single ones | F-026 rated High |

---
**Lab 2** · [All labs](README.md) · [Principle 02](../principles/02-threat-modeling.md) · [← Lab 1](lab-01-cia-and-risk.md)
