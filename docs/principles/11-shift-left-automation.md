# 11: Shift Left: Security as Code

> "If a control isn't automated and enforced, it's a suggestion."

## In plain words
Move security checks **earlier** (left) in the delivery pipeline, where problems are cheaper to fix, and make them
**automatic** so they run on every change without anyone remembering. The goal isn't to block developers. It's to give fast,
accurate feedback in the tools they already use.

```
 IDE / pre-commit ──► Pull request CI ──────────────► Build ────────► Deploy ─────────► Runtime
 secrets hook         SAST (Semgrep)                   image scan      admission policy  detection (12)
 linters              secrets scan (gitleaks)          SBOM + sign     (Kyverno/PSA)     DAST on staging
                      SCA (deps), IaC/K8s scan
```

What makes a security gate work in practice:
- **Low noise.** Start with a small, high-confidence rule set. A gate that's always red gets ignored or disabled.
- **Fail on new issues only** (a baseline) so existing debt doesn't block every PR, and pay the debt down separately.
- **A documented exception process** with an owner and an expiry.
- **Fast.** The PR checks should take minutes.

## Why it matters
Most breaches exploit **known** weaknesses: unpatched components, leaked secrets and misconfigurations. These are exactly the
classes of problem that automated, per-change checks catch before they reach production.

## In our lab
This repo's CI ([ci.sh](../../scripts/ci.sh)) currently checks manifests and links only. In this principle it becomes a real
DevSecOps pipeline, using the tools from principles 07, 09 and 10.

## Hands-on labs

### Lab 11.1: Security gates in CI ⏳
Add to `scripts/ci.sh` (and so to GitHub Actions):
1. **Secrets:** `gitleaks git .` must be clean.
2. **Kubernetes/IaC misconfiguration:** `trivy config apps/` (or `kubescape`) fails on HIGH.
3. **SAST:** your custom Semgrep rule from Lab 7.3.
Then open a pull request that deliberately breaks each gate, and capture the failed run as evidence.

### Lab 11.2: Pre-commit hooks ⏳
Add the [pre-commit](https://pre-commit.com/) framework with gitleaks, so secrets are caught before they even leave the laptop.
Explain why you still need the CI check (hooks can be skipped with `--no-verify`).

### Lab 11.3: Baselines and exceptions ⏳
Run a scanner against Juice Shop with dozens of findings. Create a baseline so only **new** findings fail CI, and write a
`SECURITY-EXCEPTIONS.md` entry format (ID, reason, owner, expiry). Add a CI check that fails on expired exceptions.

## Best-practice checklist
- [ ] Secrets, SAST, SCA and IaC scans run on every pull request
- [ ] Gates fail on new high-confidence findings; existing debt is tracked separately
- [ ] Branch protection: required checks and reviews, no direct pushes to main
- [ ] Pipelines use least-privilege, short-lived credentials (OIDC), and pinned action versions
- [ ] Security metrics tracked: time to fix, findings introduced vs fixed, exception count

## Interview questions
1. What does "shift left" mean, and what are its limits?
2. How do you introduce a security gate without developers resenting it?
3. SAST vs DAST vs SCA vs IaC scanning: what does each catch and miss?
4. How would you secure the CI/CD pipeline itself?
5. Design a DevSecOps pipeline for a team shipping 20 times a day.
