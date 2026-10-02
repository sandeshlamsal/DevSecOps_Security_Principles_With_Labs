---
name: security-triage
description: Run security scanners (Semgrep SAST, gitleaks secrets, Trivy dependencies/image/IaC, Checkov) on a codebase or container image, then triage the raw output into real, in-scope, risk-rated findings with fixes, separating them from noise with a stated reason for every set-aside. Use when asked to scan a repo, app or image for vulnerabilities, triage or prioritise scanner output, cut false positives, or produce a findings list or remediation plan. Not for a manual code-review checklist without scanners (use security-audit), writing new detection rules, or testing anything the user isn't authorised to assess.
---

# Security triage

Turn hundreds of raw scanner results into the handful that matter, and show your reasoning for everything you set aside.
A security engineer's value is in the triage, not the raw count.

## Guardrails (apply throughout)
- Only scan code and images the user owns or is authorised to assess. Live checks go only to the user's own or localhost targets.
- Prove a finding exists (a status code, a file name, a code line) and **stop there**. No exploitation beyond proof.
- **Never print secret values.** Report the file, line and rule; redact the value. To judge a value (dummy vs real), test its *shape* in a script (length, prefix, entropy) rather than printing the line.
- Never invent results. If a scanner is missing, say so and report coverage as partial.

## Step 1: Establish scope
Before scanning, find out (ask if it isn't clear from the repo):
1. **Target**: a source directory, and optionally a container image.
2. **What is deployed or served?** This is the question triage depends on. Look at Dockerfiles, manifests, static-file routes.
3. **Whose CI is this?** `.github/` in a third-party project is their pipeline, not the user's.
4. **Can you check exposure live?** If the app isn't running, say so now, confirm exposure from source instead, and list the live re-tests under Coverage gaps.

## Step 2: Run the scanners
```bash
.claude/skills/security-triage/scripts/run-scanners.sh <target-dir> [--image <ref>] [--out reports/triage/<name>]
```
Set `SEMGREP_CONFIGS` to add language rulesets (e.g. `"p/owasp-top-ten p/nodejs"`). The script lists any missing tools; relay
the install commands it prints. It takes 1–3 minutes on a medium codebase.

## Step 3: Summarise
```bash
python3 .claude/skills/security-triage/scripts/summarize.py <out-dir> --target-root <target-dir>
```
This writes `summary.md` (counts, path hints, a needs-review list grouped by rule) and `normalized.json`. Path hints are
**suggestions**: `test-fixture`, `vendored`, `example-docs` = probable noise; `iac`, `ci-config` = check exposure.
Secrets are never set aside by path, except test fixtures and vendored code, and a `private-key` hit never is.

## Step 4: Triage the needs-review groups
Work through `summary.md` group by group, highest severity first. For each group apply the rules in
[references/triage-rules.md](references/triage-rules.md). The core test:

> A result is **real, in scope** when the code or config is **deployed or served**, and attacker-controlled input can **reach** it
> without a control that neutralises it.

- **Read the code** at `file:line` before deciding. Look for the control that might already mitigate it (an allow-list, a type coercion, an auth middleware).
- **Check exposure** for anything that might be served (static directories, IaC files, keys): one request to the user's own running app settles it.
- **Look for chains**: two medium findings can make a high (for example a secret in a URL, plus logs that are publicly readable).
- For CVEs: is a fixed version available, is the vulnerable code reachable, is it on CISA KEV? A CVSS number alone isn't a risk rating.

## Step 5: Confirm what you set aside
For every probable-noise group, open at least two samples to confirm the hint is right, then record **one reason per group**
(for example: "62 gitleaks hits in `*.spec.ts`: test fixtures, values are dummy tokens"). Nothing is dropped without a reason.

## Step 6: Rate risk in context
Risk = likelihood × impact **for this deployment**, not the scanner's severity. Exposure, required authentication and which asset
is affected all move the rating. Use Critical, High, Medium and Low.

## Step 7: Report
Use the formats in [references/finding-format.md](references/finding-format.md). Deliver, in this order:
1. **Funnel**: raw → needs review → real, per tool.
2. **Findings table**: ID, severity, title, location, evidence, fix. If the repo has a finding register (for example
   `findings/README.md`), continue its ID sequence and follow its template.
3. **Set aside**: one row per group, with the count and the reason.
4. **Top 3 actions**, in order.
5. **Coverage gaps**: missing tools, no lockfile for dependency scanning, image not scanned, and so on.

Keep raw reports out of git (`reports/` is usually ignored). Commit only the curated findings.
