# Security Audit and Remediation Plan: OWASP Juice Shop v20.2.0

- **Date:** 2026-09-26 · **Scope:** the Juice Shop deployment in the local `secops-lab` kind cluster, its image, its source at tag `v20.2.0`, and this repo's CI
- **Method:** manual review ([Lab 0](../docs/labs/lab-00-foundation.md), [Lab 1](../docs/labs/lab-01-cia-and-risk.md)) + four automated scanners, with every scanner result triaged before it was recorded
- **Register:** each issue has a row in the [finding register](README.md); this page explains **how to fix each one and keep it fixed**

## Contents
1. [Summary](#1-summary)
2. [What "zero security flags" means here](#2-what-zero-security-flags-means-here)
3. [Scanner results and triage](#3-scanner-results-and-triage)
4. [All issues, by severity](#4-all-issues-by-severity)
5. [Remediation plan, in order](#5-remediation-plan-in-order)
6. [Fix details for each issue](#6-fix-details-for-each-issue)
7. [Gates that keep it at zero](#7-gates-that-keep-it-at-zero)
8. [Re-run this audit](#8-re-run-this-audit)

---

## 1. Summary

| Severity | Count | Issues |
|---|---|---|
| **Critical** | 1 | F-013 |
| **High** | 8 | F-005, F-010, F-011, F-014, F-015, F-016, F-017, F-019 (if confirmed) |
| **Medium** | 9 | F-001, F-002, F-003, F-004, F-007, F-008, F-012, F-018, F-020 |
| **Low** | 5 | F-006, F-009, F-021, F-022, F-024 |
| **Fixed** | 1 | F-023 (our own CI) |

**The three things to fix first:**
1. **Secrets exposed to anyone** (F-013, F-015, F-010): a private key in publicly served Terraform, a secret key in a public listing, and the
   login-token signing key in public source code. Any one of them compromises everything. **Rotate them; don't just hide them.**
2. **Public internal files** (F-005, F-014, F-013): documents, access logs and infrastructure code are served to anyone. Block them at the
   edge today, and remove them from the app.
3. **SQL injection in login and search** (F-016): untrusted input goes straight into SQL.

---

## 2. What "zero security flags" means here

Juice Shop is **intentionally** vulnerable (it has 100+ training challenges), so "zero findings in the app" means rewriting it. Real security
teams don't aim for zero findings; they aim for zero **unmanaged** risk. So the target has two parts:

| Layer | Target | Achievable? |
|---|---|---|
| **Platform we own**: Kubernetes manifest, cluster policies, CI | **Zero flags.** `trivy config` 0 failures, Pod Security `restricted` enforced, no secrets in our repo, actions pinned | ✅ Yes, with plan steps A1–A4 |
| **The app**: code, dependencies, exposed files | **Zero open Critical/High** issues without a documented exception (owner, reason, expiry). Medium/Low tracked with due dates | ✅ Yes, with steps B–C (a fork of the app for code fixes) |
| **Regression** | Every fixed class of issue has a **CI gate** so it can't come back | ✅ Step D |

---

## 3. Scanner results and triage

A security engineer's value is in the triage, not the raw count. Of **179 raw results**, most are noise for *this* deployment,
and the reasons are the lesson.

| Scanner (version) | What it checks | Raw | Real, in scope | Why the rest were set aside |
|---|---|---|---|---|
| **Semgrep** 1.159.0 (`p/owasp-top-ten`, `p/nodejs`) | App source code (SAST) | 43 | **16** (2 SQLi, 5 directory listings, 4 file paths, 1 code injection, 1 open redirect, 1 hard-coded key, 2 `.npmrc` without a minimum release age) | 13 are in the **upstream project's own GitHub workflows** (not deployed, not our pipeline); 10 are in `data/static/codefixes/` (training snippets shown to players, never executed); 4 are Terraform TLS settings in files that aren't deployed (they matter only because they're *served*: F-013) |
| **gitleaks** 8.30.1 | Secrets in source | 69 | **4** (JWT key F-010, Terraform private key F-013, plus 2 to triage: `routes/login.ts:64`, `frontend/.../faucet.component.ts:34`) | 62 are **test fixtures** in `*.spec.ts` files; 2 are demo users in seed data. Test fixtures still deserve a look: a real key in a test file is still a real leak |
| **Trivy image** 0.74.0 | CVEs in OS packages and Node.js libraries | 53 High/Critical | **53** (8 Critical, 45 High); **51 fixable** by upgrading | Nothing set aside yet: next comes reachability analysis per CVE ([Lab 10.2](../docs/principles/10-supply-chain-integrity.md)) |
| **Trivy config** 0.74.0 | Our Kubernetes manifest | 14 | **14**, mapping to F-001, F-002, F-004, F-009, F-021 | ⚠️ `KSV-0012 "runs as root"` is technically a false alarm (the image runs as UID 65532), but it's **right to flag it**: the manifest doesn't *guarantee* non-root. Fix: assert `runAsNonRoot: true` |

**Triage rule used:** a result is "real, in scope" if the code or config is **deployed or served** and an attacker's input can reach it.
Anything set aside is documented with a reason, never silently dropped.

---

## 4. All issues, by severity

| ID | Sev | Issue | Where | Principle | Plan step |
|---|---|---|---|---|---|
| F-013 | **Critical** | Infrastructure code served publicly, including a Terraform file with a private key | `/infrastructure/terraform/networking.tf` (HTTP 200) | 05, 09 | B1 → C1, C2 |
| F-010 | **High** | JWT signing private key hard-coded in public source | `lib/insecurity.ts:21` | 09, 08 | C2 |
| F-015 | **High** | Secret key (`premium.key`) in a public directory listing | `/encryptionkeys` | 09 | B1 → C1, C2 |
| F-005 | **High** | Public listing of internal documents, a password-manager database and backups | `/ftp` | 05 | B1 → C1 |
| F-014 | **High** | Server access logs publicly downloadable | `/support/logs` | 05, 12 | B1 → C1 |
| F-016 | **High** | SQL injection in login and search | `routes/login.ts:34`, `routes/search.ts:23` | 07 | C3 |
| F-011 | **High** | Passwords hashed with unsalted MD5 | `lib/insecurity.ts:41` | 08 | C4 |
| F-017 | **High** | 53 High/Critical dependency CVEs (51 fixable) | image `v20.2.0` | 10 | C5 |
| F-019 | High? | Possible code injection | `routes/userProfile.ts:65` | 07 | C6 (triage first) |
| F-001 | Medium | Default service account; API token mounted | manifest | 03 | A1 |
| F-002 | Medium | No securityContext | manifest | 03 | A1 |
| F-003 | Medium | No NetworkPolicy (flat network) | cluster | 04 | A2 |
| F-004 | Medium | Pod Security not enforced | namespace | 04 | A3 |
| F-007 | Medium | CORS allows any origin | app | 06 | C7 |
| F-008 | Medium | No Content-Security-Policy | app | 06 | C7 |
| F-012 | Medium | No persistent storage or backups | manifest | 01, 12 | A5 (optional) |
| F-018 | Medium | File paths built from request data | 4 file-serving routes | 07 | C6 (triage first) |
| F-020 | Medium | Possible open redirect | `routes/redirect.ts:18` | 07 | C6 (triage first) |
| F-006 | Low | `/metrics` public | app | 05 | B1 |
| F-009 | Low | Image pinned by tag, not digest | manifest | 10 | A1 |
| F-021 | Low | No CPU limit; registry not restricted | manifest | 03, 10 | A1, A4 |
| F-022 | Low | `/.well-known` has a directory listing | app | 05 | C1 |
| F-024 | Low | npm configured without a minimum release age, so a just-published (possibly malicious) package version can be installed immediately | `.npmrc`, `frontend/.npmrc` | 10, 13 | C5 |
| F-023 | Low | ✅ **Fixed:** our CI used a mutable action tag | `.github/workflows/ci.yml` | 10, 11 | done |

---

## 5. Remediation plan, in order

The order follows a rule used in real incident and vulnerability response: **stop the bleeding → fix what we own → fix the app → stop regressions.**

| Step | What | Fixes | Effort | Where you practise it |
|---|---|---|---|---|
| **B1** | **Edge block (virtual patch):** deny `/ftp`, `/infrastructure`, `/encryptionkeys`, `/support/logs`, `/metrics` at the proxy in front of the app | F-005, F-006, F-013, F-014, F-015 (exposure only) | 1 hour | Lab 5.3 |
| **C2** | **Rotate** every exposed secret: new JWT key pair, new `premium.key`, revoke the Terraform key. Move them into Kubernetes Secrets | F-010, F-013, F-015 | 2 hours | Labs 9.2, 9.3 |
| **A1** | Harden the manifest: dedicated SA, no token, securityContext, seccomp, CPU limit, digest pin | F-001, F-002, F-009, F-021 | 2 hours | Labs 3.1, 3.2 |
| **A2** | Default-deny NetworkPolicy | F-003 | 1 hour | Lab 4.1 |
| **A3** | Pod Security `restricted`: warn → audit → enforce | F-004 | 1 hour | Lab 4.2 |
| **A4** | Kyverno: signed images from trusted registries only | F-021 | 3 hours | Lab 10.3 |
| **C1** | Remove directory listings and stop shipping `infrastructure/` in the image | F-005, F-013, F-014, F-015, F-022 | 1 hour | Lab 5.3 |
| **C3** | Parameterise the SQL queries | F-016 | 2 hours | Lab 7.2 |
| **C4** | Migrate password hashing to bcrypt/Argon2id | F-011 | 3 hours | Lab 8.3 |
| **C5** | Upgrade vulnerable dependencies; rebuild the image | F-017 | 1 day | Lab 10.2 |
| **C6** | Triage F-018, F-019, F-020 by reading the code; fix the confirmed ones | F-018–F-020 | 3 hours | Lab 7.1 |
| **C7** | CORS allow-list and CSP (report-only → enforce) | F-007, F-008 | 2 hours | Lab 6.1 |
| **A5** | PersistentVolume + backup CronJob + tested restore (optional for a training app) | F-012 | 3 hours | Lab 12.x |
| **D** | CI and admission gates (section 7) | all, going forward | 1 day | Labs 11.1–11.3 |

Steps **A** and **B** change only files in *this* repo. Steps **C** need a fork of Juice Shop with your own image build. That's
realistic too: security engineers usually propose the fix as a pull request to the owning team.

---

## 6. Fix details for each issue

### B1: Block exposed paths at the edge (F-005, F-006, F-013, F-014, F-015)
A proxy in front of the app (an nginx Ingress, an API gateway or a WAF) refuses the paths before they reach the app:
```nginx
location ~ ^/(ftp|infrastructure|encryptionkeys|support/logs|metrics)(/|$) { return 404; }
location / { proxy_pass http://juice-shop.juice-shop.svc:3000; }
```
**Verify:** `for p in /ftp /infrastructure /encryptionkeys /support/logs /metrics; do curl -s -o /dev/null -w "$p %{http_code}\n" http://127.0.0.1:3000$p; done` → all `404`.
**Why this isn't enough on its own:** a virtual patch is a second layer. The files are still in the app, and anyone who already downloaded
the keys still has them, which is why C2 (rotation) comes straight after.

### C2: Rotate and externalise secrets (F-010, F-013, F-015)
1. **Assume they're compromised:** they were public. Hiding them now doesn't un-leak them.
2. Generate new keys **outside** the repo, and store them as a Kubernetes Secret (never in Git):
   ```bash
   openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out /tmp/jwt.key
   openssl pkey -in /tmp/jwt.key -pubout -out /tmp/jwt.pub
   kubectl -n juice-shop create secret generic jwt-keys --from-file=jwt.key=/tmp/jwt.key --from-file=jwt.pub=/tmp/jwt.pub
   rm /tmp/jwt.key
   ```
3. In the app, read the key from a mounted file instead of a string literal:
   ```ts
   const privateKey = fs.readFileSync(process.env.JWT_PRIVATE_KEY_FILE ?? '/secrets/jwt/jwt.key', 'utf8')
   ```
4. Deploy. Every old token stops working (a forced logout), which is the intended effect of rotation.
5. For the Terraform key: revoke it wherever it was valid, then remove it from the file and from Git history.

**Verify:** `gitleaks dir <app-fork>` shows no `private-key` hits in `lib/` or `infrastructure/`; a token signed with the old key is rejected (`401`).

### A1: Hardened manifest (F-001, F-002, F-009, F-021)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata: {name: juice-shop, namespace: juice-shop}
automountServiceAccountToken: false
---
# In the Deployment's pod template:
spec:
  serviceAccountName: juice-shop
  automountServiceAccountToken: false                           # F-001
  securityContext:
    runAsNonRoot: true                                          # makes KSV-0012 pass: asserted, not assumed
    runAsUser: 65532
    runAsGroup: 65532
    seccompProfile: {type: RuntimeDefault}                      # KSV-0030 / KSV-0104
  containers:
    - name: juice-shop
      image: bkimminich/juice-shop@sha256:8739101ade29358abb5469ee66ae78e582c97ed0a5543a4ad102e5fa5193526b   # v20.2.0, F-009
      securityContext:
        allowPrivilegeEscalation: false                         # F-002 / KSV-0001
        readOnlyRootFilesystem: true                            # KSV-0014
        capabilities: {drop: ["ALL"]}                           # KSV-0003 / KSV-0004
      resources:
        requests: {cpu: 100m, memory: 256Mi}
        limits: {cpu: "1", memory: 512Mi}                       # F-021 / KSV-0011
      volumeMounts:                                             # writable dirs only where the app must write
        - {name: tmp, mountPath: /tmp}
        # + one emptyDir per directory the app writes to under /juice-shop (find them in Lab 3.2 from the crash logs)
  volumes:
    - {name: tmp, emptyDir: {}}
```
Two scanner rules need a conscious decision, not a blind fix. `KSV-0020/0021` want a UID/GID above 10000: either set `runAsUser: 10001`
(check that the app's files are still readable) or record an exception. `KSV-0125` (trusted registries) is really solved by A4.
**Verify:** `trivy config apps/` → `Failures: 0` (or only documented exceptions); `kubectl auth can-i --list --as=system:serviceaccount:juice-shop:juice-shop -n juice-shop`
shows no extra rights; the app still serves `200`.

### A2: Default-deny network (F-003)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny, namespace: juice-shop}
spec: {podSelector: {}, policyTypes: [Ingress, Egress]}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-web, namespace: juice-shop}
spec:
  podSelector: {matchLabels: {app: juice-shop}}
  policyTypes: [Ingress]
  ingress:
    - ports: [{port: 3000, protocol: TCP}]    # narrow `from:` to the ingress controller's namespace once B1 exists
```
**Verify:** from a pod in another namespace, anything other than port 3000 times out. Egress to the internet from the app pod fails.

### A3: Enforce Pod Security (F-004)
```bash
kubectl label ns juice-shop pod-security.kubernetes.io/warn=restricted pod-security.kubernetes.io/audit=restricted --overwrite
kubectl apply -f apps/juice-shop/        # read the warnings; fix them (A1)
kubectl label ns juice-shop pod-security.kubernetes.io/enforce=restricted --overwrite
```
Put the labels in the Namespace manifest too, so they're in Git. **Verify:** a privileged test pod is **rejected** in `juice-shop`.

### C1: Remove what shouldn't be served (F-005, F-013, F-014, F-015, F-022)
- Delete the `serveIndex(...)` lines in `server.ts` (lines 268, 288, 292, 296, 300). Directory listings have no business purpose here.
- Keep `infrastructure/`, `encryptionkeys/` (private material) and `ftp/` internal docs **out of the image** (`.dockerignore`, or copy only
  `build/` in a multi-stage Dockerfile). Serve `jwt.pub` from a dedicated route if a public key must be published.
- Logs go to stdout (collected by the platform, Principle 12), never to a web-served folder.

**Verify:** the paths return `404` **without** the B1 proxy in front; `syft <new-image>` / `docker run --entrypoint ... ls` shows no `infrastructure/`.

### C3: Parameterised SQL (F-016)
Use the ORM, or bind parameters, so input is **data**, never SQL:
```ts
// routes/login.ts: before: `... WHERE email = '${req.body.email}' AND password = '${hash(...)}' ...`
const user = await UserModel.findOne({ where: { email: req.body.email ?? '', password: security.hash(req.body.password ?? '') } })

// routes/search.ts: before: `... name LIKE '%${criteria}%' ...`
models.sequelize.query(
  'SELECT * FROM Products WHERE ((name LIKE :q OR description LIKE :q) AND deletedAt IS NULL) ORDER BY name',
  { replacements: { q: `%${criteria}%` } })
```
**Verify:** Semgrep `express-sequelize-injection` no longer reports `routes/login.ts` or `routes/search.ts`; login and search still work;
a Semgrep custom rule in CI blocks template-string SQL from coming back (Lab 7.3).

### C4: Password hashing (F-011)
```ts
import bcrypt from 'bcrypt'
const hash = await bcrypt.hash(password, 12)          // on register / password change
const ok = await bcrypt.compare(password, user.password)
```
**Migration without a mass reset:** on each successful login with an old MD5 hash, re-hash the password with bcrypt and save it. After a
deadline, force a reset for accounts that never logged in. (This also changes C3's login lookup: find by email, then `bcrypt.compare`.)

### C5: Vulnerable dependencies (F-017)
1. `npm outdated` / `npm audit` in the fork; upgrade direct dependencies (for example `jsonwebtoken`, `express-jwt`, `crypto-js`, `lodash`).
2. For vulnerable **transitive** packages, use `overrides` in `package.json`, then run the tests.
3. Rebuild on an updated base image (fixes the OpenSSL `libssl3t64` CVE).
4. Add a minimum release age to `.npmrc` (F-024), so brand-new package versions wait a few days before they can be installed. Most malicious releases are caught and pulled within that window.
5. The 2 CVEs without a fix (`decompress`, `marsdb`): check whether the vulnerable code is reachable. If it is, replace the package; if not,
   record a **time-limited exception** with the reasoning.

**Verify:** `trivy image --severity HIGH,CRITICAL --ignore-unfixed <new-image>` → 0.

### C6: Triage, then fix (F-018, F-019, F-020)
For each one, read the code and answer: can request data reach this line, and is there a working control on every path? Then fix or mark it
false positive **with the reason**. Typical fixes: resolve the path and check it stays under an allow-listed base directory (F-018); never
evaluate strings built from input (F-019); redirect only to an allow-list of exact URLs (F-020).

### C7: CORS and CSP (F-007, F-008)
```ts
app.use(cors({ origin: ['http://localhost:3000'] }))                 // exact origins, never '*' with credentials
app.use(helmet.contentSecurityPolicy({ reportOnly: true,              // step 1: report-only, read violations
  directives: { defaultSrc: ["'self'"], imgSrc: ["'self'", 'data:'] } }))
```
When the browser console shows no violations during normal use, switch `reportOnly` to `false`.

### A5: Durable data (F-012, optional)
PersistentVolumeClaim for `/juice-shop/data`, a backup CronJob, and a **tested restore**. A backup nobody has restored is only a hope.

---

## 7. Gates that keep it at zero

Each fix is only finished when a gate stops it coming back. Added to `scripts/ci.sh` (and so to GitHub Actions) in Lab 11.1:

| Gate | Command (fails the build) | Protects |
|---|---|---|
| Secrets | `gitleaks git . --exit-code 1` | F-010, F-013, F-015 |
| K8s misconfig | `trivy config --exit-code 1 --severity LOW,MEDIUM,HIGH,CRITICAL apps/` | F-001, F-002, F-009, F-021 |
| Image CVEs | `trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed <image>` | F-017 |
| SAST | `semgrep scan --error --config p/owasp-top-ten --config .semgrep/` (custom rules) | F-016, F-018–F-020 |
| CI supply chain | `semgrep scan --error --config p/github-actions .github/` | F-023 |
| Manifests valid | `kubeconform -strict` (already in CI) | — |
| **Admission** (in the cluster) | Pod Security `restricted` + Kyverno signed-image policy | F-002, F-004, F-021 — even if someone bypasses CI |
| Exceptions | CI fails if any entry in `SECURITY-EXCEPTIONS.md` is past its expiry date | keeps accepted risk honest |

---

## 8. Re-run this audit

```bash
git clone -q --depth 1 --branch v20.2.0 https://github.com/juice-shop/juice-shop.git tmp/juice-shop   # tmp/ and reports/ are git-ignored
semgrep scan --config p/owasp-top-ten --config p/nodejs --metrics=off --json -o reports/semgrep.json tmp/juice-shop
gitleaks dir tmp/juice-shop --report-path reports/gitleaks.json
trivy image --severity HIGH,CRITICAL --format json -o reports/trivy-image.json bkimminich/juice-shop:v20.2.0
trivy config --format json -o reports/trivy-config.json apps/
# exposure check (lab running, `make open`):
for p in /ftp /infrastructure /encryptionkeys /support/logs /metrics /.well-known; do
  printf "%-16s %s\n" "$p" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000$p)"; done
```
Results on 2026-09-26: Semgrep 43, gitleaks 69, Trivy image 53 High/Critical, Trivy config 14, and all six paths → `200`.
Re-run after each plan step, and update the counts and the [finding register](README.md).
