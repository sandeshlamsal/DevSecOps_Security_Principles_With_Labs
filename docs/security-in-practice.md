# What This Lab Proves

A recruiter- and interviewer-facing summary: each security principle mapped to **what was built**, the **evidence**, and the **lesson**.
Everything here was executed against a live cluster and is reproducible from the [lab guides](labs/README.md); every change is a green
commit on [both CI pipelines](../.github/workflows/). Start at the [INDEX](../INDEX.md) for the full map.

## By the numbers (2026-09-26)
- **13 executed lab guides** with real commands, output and issues logs
- **35 findings** tracked by risk: 6 Fixed, 3 Mitigated, 1 verified false-positive, the rest scheduled with a fix path
- **7 blocking CI security gates** + pre-commit hooks + a SARIF report to GitHub code scanning
- **7 active exceptions**, each with an owner and an **expiry** enforced by CI (nothing accepted silently or forever)
- A **secure-by-default Azure Terraform** environment (Checkov: 18 passed, 0 failed)

## The full loop the lab implements
**Prevent → Detect → Respond → Improve → Gate → Govern**, on one app, end to end.

---

## Principle → build → evidence → lesson

| # | Principle | What was built | Evidence | Lesson |
|---|---|---|---|---|
| 01 | [CIA & risk](principles/01-cia-triad-and-risk.md) | Asset inventory + CIA ratings for 17 assets | [asset model](../threat-models/juice-shop-assets.md); a pod restart **erased** a new account (F-012) | Rate by risk-in-context, not scanner severity; a leaked signing key outranks a scary-sounding bug |
| 02 | [Threat modelling](principles/02-threat-modeling.md) | STRIDE model from source review | [21 threats](../threat-models/juice-shop.md); found SSRF, B2B `eval`, XXE (F-027/028/029) before any exploit | Model the design, not just the endpoints; combinations (query-string secret + public logs) raise the risk |
| 03 | [Least privilege](principles/03-least-privilege.md) | Hardened pod: dedicated SA, no token, non-root, dropped caps, seccomp, digest pin | [Lab 4](labs/lab-04-least-privilege.md); F-001/002/009 Fixed; `kubectl auth can-i` → no secrets/pods | Verify with `trivy config` + `can-i`, don't assume; a writable-FS app is a real "control vs app" trade-off |
| 04 | [Defence in depth](principles/04-defense-in-depth.md) | Default-deny NetworkPolicy + enforced Pod Security `restricted` | [Lab 5](labs/lab-05-defense-in-depth.md); cross-ns probe **timed out**, privileged pod **rejected** | An ingress rule with only `ports:` allows all sources — the `from:` selector is what segments |
| 05 | [Attack surface](principles/05-attack-surface-reduction.md) | Endpoint inventory + hardened reverse-proxy virtual patch | [Lab 3](labs/lab-03-attack-surface-and-defaults.md), [Lab 6](labs/lab-06-virtual-patch-proxy.md); the exposed **private key** now 404s | Triage before reporting (the open-redirect was already mitigated); virtual-patch fast, then fix durably |
| 06 | [Secure defaults](principles/06-secure-defaults.md) | Header review + report-only CSP; error-verbosity finding | [Lab 3](labs/lab-03-attack-surface-and-defaults.md); F-007/008/031 | The safe state must be the default; errors leak framework/version/paths |
| 07 | [Never trust input](principles/07-never-trust-input.md) | Custom Semgrep rule = SQLi regression gate | [Lab 7](labs/lab-07-sast-supply-chain.md); fires on the 2 real files, passes the fix, self-tested | Turn one fix into a guardrail; reward the correct fix, don't ban the API |
| 09 | [Data & secrets](principles/09-protect-data-and-secrets.md) | gitleaks in CI + pre-commit; found a real self-inflicted FP and fixed the scan gap | [Lab 8](labs/lab-08-precommit-and-baselines.md); `--staged` vs `--pre-commit` gotcha documented | A blocked exposure ≠ a rotated secret — F-013/015 stay open until keys are rotated |
| 10 | [Supply chain](principles/10-supply-chain-integrity.md) | SBOM+scan+sign pipeline; digest pins; SHA-pinned actions | [build-sign.yml](../.github/workflows/build-sign.yml); F-023 fixed | Pin by digest/SHA; "0 CVEs" is the wrong goal, "no unaccepted exploitable HIGH" is right |
| 11 | [Shift left](principles/11-shift-left-automation.md) | 7 blocking gates + pre-commit + expiring exceptions | [security.yml](../.github/workflows/security.yml), [Lab 8](labs/lab-08-precommit-and-baselines.md) | A gate that fails on old debt gets disabled; fail on *new* issues, track the rest with expiry |
| 12 | [Assume breach](principles/12-assume-breach.md) | Falco runtime detection + a full incident game day | [Lab 10](labs/lab-10-runtime-detection.md), [Lab 11](labs/lab-11-incident-game-day.md); detected + contained a live intrusion | Detection is the safety net for when prevention fails; a game day turns "we're covered" into a to-do list |
| 13 | [AI-era security](principles/13-ai-era-security.md) | OWASP LLM Top 10 review of the chatbot agent + test plan + process | [Lab 9](labs/lab-09-ai-security.md), [Lab 12](labs/lab-12-ai-testing-and-process.md); F-032 (coupon policy in the prompt) | Least agency; authorise every tool **in code**, never in the prompt; the model is not a boundary |

## The three war stories (interview-ready)
1. **A private key, downloadable by anyone.** The audit's Critical (F-013): a Terraform file with a private key served at
   `/infrastructure`. I virtual-patched the exposure at a reverse proxy the same day (404), and kept the finding **open** because the
   real fix is key **rotation** — a blocked door doesn't un-leak what already left. ([Lab 6](labs/lab-06-virtual-patch-proxy.md))
2. **The scanner was wrong, twice, in opposite directions.** Semgrep flagged an open redirect that was already mitigated (downgraded to a
   false positive), while Trivy "runs as root" on a non-root image was worth keeping (the manifest didn't *assert* non-root). Triage is the
   job. ([Lab 3](labs/lab-03-attack-surface-and-defaults.md), [REMEDIATION §3](../findings/REMEDIATION.md#3-scanner-results-and-triage))
3. **An AI agent that authorises in the prompt.** The chatbot's coupon tool trusts a discount the model chooses, capped only by prompt
   text — so injection mints a 50%-off coupon. The same app gets it *right* elsewhere (`getOrderById` checks ownership in code). Fix: cap
   and authorise in code. ([Lab 9](labs/lab-09-ai-security.md))

## Honest gaps (what a real report would say)
- F-013/F-015 exposure is blocked but the keys need rotation (the fork + own signed build, capstone M2–M3).
- Segmentation and Pod Security are enforced on `juice-shop` but not yet cluster-wide (game-day action items A1/A4).
- Kubernetes audit logging (Lab 12.2) and cloud labs (Azure Phase 2) are planned, not done.
- Every accepted gap is in [SECURITY-EXCEPTIONS.md](../SECURITY-EXCEPTIONS.md) with an owner and an expiry.

> The point of the lab isn't a perfect score. It's judgement: find real risk, fix what matters first, prove the fix, gate the regression,
> and be honest about what's left.
