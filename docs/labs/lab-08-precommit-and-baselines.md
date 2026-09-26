# Lab 8: Pre-commit Hooks + Baselines & Exceptions (Execution Guide)
**Lab 8** · [All labs](README.md) · [Principle 11](../principles/11-shift-left-automation.md) · [← Lab 7](lab-07-sast-supply-chain.md)

> **Goal:** shift the fastest checks left to the developer's laptop (Lab 11.2), and formalise how existing debt and accepted risk are
> handled so gates don't block everyone on day one (Lab 11.3). **Executed:** 2026-09-26.

---

## Part A: Pre-commit hooks (Lab 11.2)

A pre-commit hook catches problems **before** a commit exists — seconds of feedback, in the editor's flow. It does **not** replace the CI
gate, because hooks can be skipped (`git commit --no-verify`); it's the first of two layers.

[.pre-commit-config.yaml](../../.pre-commit-config.yaml) reuses the **same pinned tools as CI** (gitleaks 8.30.1, Semgrep + our `.semgrep`
rules), so local and server checks can't drift:
```yaml
repos:
  - repo: local
    hooks:
      - id: gitleaks
        entry: gitleaks git --staged --redact --no-banner --exit-code 1   # scans STAGED changes
        language: system
        pass_filenames: false
      - id: semgrep-custom-sqli
        entry: semgrep scan --config .semgrep/ --error --quiet ...          # the F-016 regression rule
        language: system
        types: [ts]
        exclude: '^\.semgrep/'
```
Install once per clone:
```bash
pip install pre-commit && pre-commit install
```

### Verified behaviour
| Test | Result |
|---|---|
| Stage a real secret (`db_password = "s3cr3t_…"`) → `pre-commit run gitleaks` | **`leaks found: 1` — commit blocked** |
| Stage a vulnerable `.ts` (`sequelize.query(\`…${email}…\`)`) → SAST hook | **flagged with the fix message — commit blocked** |
| Clean repo → `pre-commit run --all-files` | **Passed / Skipped** — legitimate commits aren't blocked |

### A gitleaks flag gotcha (issue log)
`gitleaks git --pre-commit` does **not** scan fully-staged content in 8.30.1; `gitleaks git --staged` does. The hook (and the local check in
[security-scan.sh](../../scripts/security-scan.sh)) use `--staged`. Also, common example keys (e.g. AWS `AKIAIOSFODNN7EXAMPLE`) are
allowlisted by gitleaks, so test with a realistic non-example secret.

## Part B: Baselines and exceptions (Lab 11.3)

A gate that fails on *existing* debt blocks every PR and gets disabled. The rule: **fail on new issues; track existing debt with an owner
and an expiry.** This repo already implements that (built across Labs 0–7):

| Mechanism | File | What it does |
|---|---|---|
| Exceptions register | [SECURITY-EXCEPTIONS.md](../../SECURITY-EXCEPTIONS.md) | Every accepted risk: ID, scope, reason, **owner, expiry** |
| Scanner suppressions tied to it | [.trivyignore](../../.trivyignore), inline `checkov:skip=…:EXC-nnn` | Each carries an `exp:` date / EXC id |
| Verified false positives | [.gitleaksignore](../../.gitleaksignore) | Only after triage, with a reason |
| Enforcement | [scripts/check-exceptions.py](../../scripts/check-exceptions.py) | **Fails CI** if an exception is expired, or a suppression has no matching row |

### Verified behaviour (from earlier labs, re-confirmed)
```bash
python3 scripts/check-exceptions.py          # exceptions: 7 registered, next expiry 2026-12-14; problems: 0
# planting an undocumented checkov:skip or an expired exp: date makes it exit 1 (proven in Lab: negative tests)
```
Current registry: **7 active exceptions**, each with a compensating control and an expiry, so nothing is accepted silently or forever.

---

## Lab 8 exit checklist
- [x] `.pre-commit-config.yaml` reuses the CI-pinned gitleaks + Semgrep rules
- [x] Secret hook blocks a staged secret; SAST hook blocks staged vulnerable TS; clean repo passes
- [x] Documented the `--staged` vs `--pre-commit` gitleaks difference and the example-key allowlist
- [x] Baseline/exception model confirmed: expiry-enforced, CI-gated, 7 active exceptions

**Interview takeaway:** "How do you roll out a security gate to a team with lots of existing findings?" Fast pre-commit hooks for new work,
a baseline so the gate fails only on *new* issues, and an exceptions register where every accepted risk has an owner and an expiry.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L8-ISSUE-1 | The gitleaks hook passed on a staged secret | `--pre-commit` doesn't scan staged content in gitleaks 8.30.1; and the AWS `…EXAMPLE` key is allowlisted | Use `--staged` for a commit hook; test with a realistic secret |

---
**Lab 8** · [All labs](README.md) · [Principle 11](../principles/11-shift-left-automation.md) · [← Lab 7](lab-07-sast-supply-chain.md)
