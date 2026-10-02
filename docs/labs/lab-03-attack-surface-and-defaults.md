# Lab 3: Attack Surface and Secure Defaults (Execution Guide)
**Lab 3** · [All labs](README.md) · Principles [05](../principles/05-attack-surface-reduction.md) & [06](../principles/06-secure-defaults.md) · [← Lab 2](lab-02-threat-modeling.md)

> **Goal:** inventory what Juice Shop exposes without a login, and review its HTTP secure-defaults (headers, CORS, errors).
> **Covers:** Labs 5.1–5.2 (attack surface) and 6.1–6.2 (secure defaults). **Time:** ~1.5 h. **Executed:** 2026-09-26.

---

## Part A: Attack-surface inventory (Principle 05)

### A1: What's reachable without authentication?
```bash
B=http://127.0.0.1:3000
for p in '/rest/admin/application-configuration' '/api/Products' '/api/Feedbacks' '/api/Quantitys' \
         '/api/Recycles' '/api/SecurityQuestions' '/api/Users' '/api/BasketItems' '/api/Complaints' \
         '/ftp' '/encryptionkeys' '/support/logs' '/metrics'; do
  printf "%-42s %s\n" "$p" "$(curl -s -o /dev/null -w '%{http_code}' "$B$p")"; done
```

| Endpoint | Unauth | Verdict |
|---|---|---|
| `/api/Users` | **401** | ✅ access control present |
| `/api/BasketItems`, `/api/Complaints` | **401** | ✅ protected (contain user data) |
| `/api/Products`, `/api/SecurityQuestions` | 200 | Expected (public catalogue / question list) |
| `/api/Feedbacks`, `/api/Quantitys`, `/api/Recycles` | 200 | ⚠️ exposes other users' feedback and internal records |
| `/rest/admin/application-configuration` | 200 | ⚠️ full app config readable (**F-030**) |
| `/ftp`, `/encryptionkeys`, `/support/logs`, `/metrics` | 200 | ❌ F-005, F-006, F-014, F-015 (from Lab 0/1) |

**Positive:** the access-control layer is not absent. The most sensitive collections (`Users`, `BasketItems`, `Complaints`) correctly
return 401. That's [defence in depth](../principles/04-defense-in-depth.md) partly working, and worth stating in a real report.

### A2: The config leak (F-030)
```bash
curl -s "$B/rest/admin/application-configuration" | python3 -c "import json,sys;print(list(json.load(sys.stdin)['config']))"
# -> server, application, challenges, hackingInstructor, products, memories, ctf
```
It exposes feature flags, product data and CTF settings, and the **public** Google OAuth client ID. It does **not** leak server secrets
(no signing key, no passwords). Rated **Low–Medium**: it hands an attacker a map of the app's features and configuration. Fix: require
admin auth, or strip internal keys before returning.

### A3: Open redirect — triage of F-020
```bash
grep -n "redirectAllowlist\|startsWith" tmp/juice-shop/routes/redirect.ts tmp/juice-shop/lib/insecurity.ts
curl -s -o /dev/null -w '%{http_code}\n' "$B/redirect?to=https://owasp.org"                 # 406 (not allow-listed)
curl -s -o /dev/null -w '%{http_code}\n' "$B/redirect?to=http://evil.test/%3Fx%3Dhttps://github.com/bkimminich/juice-shop"  # 406
```
> ⚠️ **Corrected 2026-10-02 — this conclusion was wrong.** The real gate, `isRedirectAllowed()` in `lib/insecurity.ts:136`, uses
> `url.includes(allowedUrl)`, so any URL that *contains* an allow-listed URL passes: **F-020 is a real open redirect (Medium)**.
> Two mistakes: the `startsWith` read here is in `isUnintendedRedirect()`, which only detects the challenge; and the bypass test above used
> `github.com/bkimminich/juice-shop`, which isn't on the allow-list (the entry is `github.com/juice-shop/juice-shop`), so the 406 proved
> nothing. Caught when the [security-triage skill](lab-13-security-triage-skill-run.md) re-read the code. Lesson: read the function that
> actually *makes* the decision, and test a bypass with an input that's genuinely allow-listed.

---

## Part B: Secure defaults (Principle 06)

### B1: HTTP response headers
```bash
curl -sI "$B/" | grep -iE 'x-frame|x-content|content-security|strict-transport|access-control|referrer|permissions-policy'
```
```
Access-Control-Allow-Origin: *          ❌ F-007
X-Content-Type-Options: nosniff         ✅
X-Frame-Options: SAMEORIGIN             ✅
                                        ❌ no Content-Security-Policy (F-008)
                                        ❌ no Referrer-Policy, no Permissions-Policy
```
HSTS is not applicable here (plain HTTP on localhost); in production behind TLS it would be required, and is added at the reverse proxy
([Linux notes §7](../linux-security/README.md#7-reverse-proxies)).

**Proposed CSP** (roll out in report-only first, then enforce): for this Angular app, start from
```
Content-Security-Policy-Report-Only:
  default-src 'self';
  img-src 'self' data:;
  style-src 'self' 'unsafe-inline';        # Angular injects styles; tighten with nonces/hashes later
  script-src 'self';
  connect-src 'self';
  frame-ancestors 'self';
  base-uri 'self';
  form-action 'self'
```
Watch the browser console for violations during normal use, fix them, then switch the header to enforcing. Closes **F-008**.

### B2: Error handling (F-031)
```bash
curl -s -X POST -H 'Content-Type: application/json' -d '{bad' "$B/rest/user/login" | grep -oiE 'node_modules|/juice-shop/build|at Object|SyntaxError' | sort | uniq -c
```
Malformed JSON returns a full HTML error page with the **exception message, a stack trace, `node_modules` paths and internal
`/juice-shop/build` paths**. That tells an attacker the framework, versions and file layout. **F-031**, Medium. Fix: a generic error to the
client (message + correlation ID), full detail only in server logs; disable the verbose error handler in production.

---

## New findings

| ID | Finding | Risk | Principle |
|---|---|---|---|
| F-030 | `/rest/admin/application-configuration` readable unauthenticated (feature flags, product/CTF config; no server secrets) | Low–Medium | [05](../principles/05-attack-surface-reduction.md) |
| F-031 | Verbose error pages leak stack traces, `node_modules` and build paths | Medium | [06](../principles/06-secure-defaults.md) |
| F-020 | Open redirect — ~~downgraded~~ **corrected 2026-10-02: real** (`includes()` gate; see note in A3) | Medium | [07](../principles/07-never-trust-input.md) |

---

## Lab 3 exit checklist
- [x] Unauthenticated attack surface inventoried; protected vs exposed endpoints separated
- [x] Config-leak endpoint checked for secrets (none) and rated (F-030)
- [x] Open-redirect finding triaged against the source (verdict later corrected: real, see A3)
- [x] Security headers reviewed; a report-only CSP drafted (F-008)
- [x] Error verbosity confirmed and recorded (F-031)

**Interview takeaway:** "How do you assess a web app's attack surface and its defaults?" Enumerate unauthenticated endpoints, separate
expected exposure from real leaks, read the code before calling something a bug (the redirect was already safe), and check the headers
and error pages that shape every response.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L3-ISSUE-1 | `?` in a URL gave `zsh: no matches found` | zsh globs `?`; the URL wasn't quoted | Quote URLs with query strings in zsh |
| L3-ISSUE-2 | Semgrep flagged an open redirect (F-020) that turned out to be mitigated | The control is in a helper (`isRedirectAllowed`), not the route | Triage every scanner hit against the code before reporting it |
| L3-ISSUE-3 | (found 2026-10-02) The F-020 downgrade above was wrong | Read the challenge-detection helper instead of the gate, and tested with a non-allow-listed URL | Find the code that actually decides; make the test input satisfy the allow-list it's meant to bypass |

---
**Lab 3** · [All labs](README.md) · Principles [05](../principles/05-attack-surface-reduction.md) & [06](../principles/06-secure-defaults.md) · [← Lab 2](lab-02-threat-modeling.md)
