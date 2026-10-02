# Triage rules

Loaded by the security-triage skill during Step 4. Each rule came from a real triage in this repo's labs; the worked examples are the
ground truth from the OWASP Juice Shop v20.2.0 audit (`findings/REMEDIATION.md`).

## The rules

| # | Rule | Why |
|---|---|---|
| R1 | **In scope = deployed or served + reachable by attacker input + no neutralising control.** All three. | Scanners can't see deployment or data flow; you can |
| R2 | **Read the code before deciding.** Find the sink, trace where its input comes from, look for the control. | Half of "possible X" results are mitigated one function away |
| R3 | **Secrets: never dismiss by path.** A real key in a test file or Terraform is still a leak. Test fixtures need a look at the value's shape (dummy vs real). | The most serious finding in the audit was a private key in an IaC file |
| R4 | **"Served" beats "deployed".** A file in a web-served directory is exposed even if it's "just config". Verify with one request. | IaC, backups, logs and keys in static dirs |
| R5 | **Third-party CI isn't your pipeline.** `.github/` of a cloned upstream project is out of scope unless the user runs it. | 13 Semgrep hits in Juice Shop's own workflows |
| R6 | **Examples and training snippets aren't executed**, unless they're served or imported. Confirm by checking imports. | 10 Semgrep hits in `data/static/codefixes/` |
| R7 | **Keep "technically false" alarms that point at a missing assertion.** If the config doesn't *guarantee* the safe state, flag it. | Trivy "runs as root" on a non-root image: the manifest didn't assert `runAsNonRoot` |
| R8 | **Rate chains, not just single findings.** | Password in a URL query string (Medium) + publicly served logs (High) = credentials harvestable by anyone |
| R9 | **CVEs: fixable? reachable? exploited in the wild (CISA KEV, EPSS)?** "Zero CVEs" isn't the goal; "no unaccepted, exploitable High/Critical" is. | 53 → 60 High/Critical in one week with no code change |
| R10 | **Every set-aside gets a written reason; every accepted risk gets an owner and an expiry.** | Silent drops are how real issues get lost |

## Worked examples (ground truth)

| Scanner result | Hint | Correct verdict | The trap |
|---|---|---|---|
| gitleaks `private-key` in `infrastructure/terraform/networking.tf` | iac | **Critical, real**: the directory is publicly served (`GET /infrastructure/... → 200`) | A path hint ("iac") made it look like noise. R3 + R4 |
| gitleaks `private-key` in `lib/insecurity.ts:21` | none | **High, real**: JWT signing key in public source, anyone can forge sessions | — |
| gitleaks ×62 in `*.spec.ts` | test-fixture | Set aside: dummy tokens in unit tests (sampled) | Reporting all 62 as leaks |
| gitleaks ×2 in `data/static/users.yml` | none | Low: demo seed users for the training app | Rating seed data as a breach |
| Semgrep `express-open-redirect` `routes/redirect.ts` | none | **False positive**: allow-list + `startsWith`; a bypass attempt returns 406 | Trusting the scanner. R2 |
| Semgrep `express-sequelize-injection` `routes/login.ts:34`, `search.ts:23` | none | **High, real**: request body interpolated into SQL | — |
| `$where: 'this.product == ' + productId` | none | **Low**: `productId = Number(id)` neutralises injection; fragile pattern | Over-rating without reading the coercion. R2 |
| Semgrep ×13 in `.github/workflows/` (upstream) | ci-config | Set aside: upstream project's pipeline, not deployed | Rating someone else's CI. R5 |
| Semgrep ×10 in `data/static/codefixes/` | example-docs | Set aside: challenge snippets shown to players, never executed | R6 |
| Trivy `KSV-0012` "runs as root" | none | **Keep** (Medium): image is non-root but the manifest doesn't assert it | Dismissing it as false. R7 |
| `GET /rest/user/change-password?current=…&new=…` + public `/support/logs` | — | **High (chain)**: passwords land in a log anyone can download | Rating each half alone. R8 |

## Tool gotchas
- `trivy config` takes **one** directory per call.
- `trivy fs` finds dependency CVEs only from **lockfiles** (`package-lock.json`, `go.sum`…). No lockfile → scan the built image instead, and report the gap.
- `gitleaks git --staged` scans staged changes; `--pre-commit` doesn't (8.30.x). `gitleaks dir` scans files regardless of git.
- gitleaks allowlists well-known example keys (e.g. AWS `AKIAIOSFODNN7EXAMPLE`): test with a realistic value.
- Checkov phones home for guideline text unless `--skip-download`; Terraform variables without values cause false failures (pass `--var-file`).
- Semgrep registry rules update independently of the CLI version, so raw counts can drift between runs.
