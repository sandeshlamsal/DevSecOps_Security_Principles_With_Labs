# Lab 13: First Real Run of the security-triage Skill (Execution Record)
**Lab 13** · [All labs](README.md) · Skill: [security-triage](../../.claude/skills/security-triage/SKILL.md) · [Guide](../skills/README.md)

> **Request:** `/security-triage scan tmp/juice-shop with the bkimminich/juice-shop:v20.2.0 image`
> **Executed:** 2026-10-02. Raw reports: `reports/triage/juice-shop-2026-10-02/` (git-ignored).
> **Outcome:** 407 raw results → 217 needing review → **6 new or changed findings**, including **one correction of an earlier verdict**.

---

## Step 1: Scope
| Question | Answer (from the source) |
|---|---|
| What's in the image? | `COPY . /juice-shop` minus `.dockerignore`: so `infrastructure/`, `terraform/`, `encryptionkeys/`, `data/` and `.github/` all ship; `test/` and `.npmrc` don't |
| What's served without login? | `/infrastructure` (listing + files), `/ftp`, `/encryptionkeys`, `/support/logs`, `/.well-known` (`server.ts:268–300`) |
| Whose CI? | `.github/` is the upstream project's pipeline: shipped, never executed or served |
| Lockfile? | None, so dependency CVEs come from the image scan |
| Live checks possible? | No: Docker stopped, lab cluster torn down. Exposure is confirmed from source + the live requests recorded in Labs 0–1 |

## Steps 2–3: Scan and summarise
All six scans ran (Semgrep `p/owasp-top-ten p/nodejs`, gitleaks, Trivy fs/config/image, Checkov). The image scan pulled from the
registry without a Docker daemon.

## Funnel
| Tool | Raw | Needs review | Real, in scope |
|---|---|---|---|
| Semgrep | 43 | 33 | 16 hits → SQLi ×2, `eval` RCE, 5 served directory listings, `sendFile` ×4 (1 real bypass), open redirect, JWT key, `.npmrc` ×2 |
| gitleaks | 69 | 7 | 6 (JWT signing key; the Terraform key ×2, the same key; seed-account passwords ×3) |
| Trivy image | 60 | 60 | 60 tracked (57 fixable, 0 on CISA KEV); **2 escalated** as reachable |
| Trivy config | 89 | 37 | 3 Low (Dockerfile: no HEALTHCHECK, `:latest`) |
| Checkov | 146 | 80 | 7 (same 3 Dockerfile Lows + 4 seed passwords) |
| Trivy fs | 0 | 0 | — (no lockfile: coverage gap) |

## Step 4: Triage results (new or changed)

| ID | Severity | Finding | Location | Evidence | Fix |
|---|---|---|---|---|---|
| **F-019** | **Critical** (was "High if confirmed") | Server-side code execution: a `#{…}` username is passed to `eval()` | `routes/userProfile.ts:65` | `username = eval(code)`; registration is open | Remove `eval`; treat usernames as data |
| **F-020** | **Medium (corrected: real)** | Open redirect | `lib/insecurity.ts:136` | Gate is `url.includes(allowedUrl)` | Exact-match allow-list |
| **F-036** | High | JWT algorithm confusion (CVE-2015-9235) reachable in auth | `express-jwt` 0.1.3, `jsonwebtoken` 0.4.0 (direct) | `isAuthorized()` protects 23 routes | Upgrade both; pin `algorithms: ['RS256']` |
| **F-037** | High | `marsdb` Critical advisory, **no fixed version** | `data/mongodb.ts` (reviews, orders) | Direct dependency, reachable | Replace the package; time-boxed exception |
| **F-018** | Medium (confirmed) | `.md/.pdf` allow-list checked **before** null bytes are stripped | `routes/fileServer.ts` | Other file servers reject `/` and stay confined | Normalise, then validate |
| **F-038** | Low | Plaintext seed-account passwords in source, shipped in the image | `data/static/users.yml`, `routes/login.ts` | `data/` isn't dockerignored | Hash seed data |
| F-017 | (update) | Image CVEs 53 → **60** in a week, no app change; none on KEV | image | Trivy DB update | Weekly re-scan (already scheduled) |

Re-confirmed, unchanged: F-010 (JWT signing key in source), **F-013** (the Terraform private key, the *same* key in `infrastructure/` and
`terraform/`; the `infrastructure/` copy is publicly served), F-016 (SQLi in `login.ts`/`search.ts`), F-024 (`.npmrc`, build-time only).

### The correction (F-020)
Lab 3 had downgraded the open redirect to a false positive. Rule R2 ("read the code that actually decides") exposed two mistakes: Lab 3 read
`startsWith` in `isUnintendedRedirect()`, which only *detects the challenge*, and its bypass test used `github.com/bkimminich/juice-shop`,
which isn't on the allow-list, so the 406 proved nothing. The real gate uses `includes()`. The verdict was corrected in the register, Lab 3,
Lab 12, the skill's own ground-truth rules, the skills guide and the "what this lab proves" page.

## Step 5: Set aside (each group sampled)
| Tool | Group | Count | Reason |
|---|---|---|---|
| gitleaks | `test/**` | 62 | Test tokens and TOTP secrets for test accounts (3 sampled); `test/` is also excluded from the image |
| gitleaks | `faucet.component.ts` | 1 | Blockchain contract addresses: public by design |
| Semgrep, Checkov | `.github/workflows/` | 13 + 14 | Upstream project's CI: shipped but never executed or served |
| Semgrep, Checkov, Trivy config | `data/static/codefixes/` | 10 + 63 + 48 | Read as **text** by `routes/vulnCodeFixes.ts` for the coding-challenge UI; never executed |
| Semgrep, Checkov, Trivy config | `infrastructure/terraform`, `terraform/` design rules | 4 + 52 + 34 | Training Terraform, never deployed by the app; its real risk (served private key) is F-013 |
| Checkov | `CKV_SECRET_6` in `i18n/*.json` | 6 | Translation labels such as `"LABEL_PASSWORD": "Contrasenya"` |

## Top 3 actions
1. **Rotate and remove the exposed keys** (F-013 Terraform key, F-010 JWT key). The proxy (Lab 6) blocks access but the keys are already public.
2. **Remove `eval` from the profile page** (F-019): any registered user can run code on the server.
3. **Fix the auth path**: upgrade `express-jwt`/`jsonwebtoken` (F-036) and parameterise the SQL (F-016).

## Coverage gaps
- No lockfile, so `trivy fs` found nothing; dependency coverage comes from the image only.
- No live checks today (Docker stopped): F-020 and the served directories are confirmed from source, plus Labs 0–1 live evidence. Re-test when the lab is up.
- Semgrep registry rules aren't pinned, so raw counts can drift between runs.
- Guardrail slip: one check printed the first 5 characters of the JWT key (`MIICX`, the standard RSA key prefix, not sensitive). Later checks printed line numbers only.

## What this run says about the skill
- **It worked as designed:** scope first, scripts for the deterministic part, judgement against written rules, every set-aside with a reason.
- **It found something the manual audit got wrong** (F-020) and confirmed two "needs triage" items (F-019 Critical, F-018 Medium).
- **Improvement for next time:** the scope step should note when live checks are impossible, and the skill should list how to re-test them later.
