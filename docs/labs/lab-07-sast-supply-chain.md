# Lab 7: SAST Custom Rule + Supply-Chain Pipeline (Execution Guide)
**Lab 7** · [All labs](README.md) · Principles [07](../principles/07-never-trust-input.md), [10](../principles/10-supply-chain-integrity.md), [11](../principles/11-shift-left-automation.md) · [← Lab 6](lab-06-virtual-patch-proxy.md)

> **Goal:** turn one confirmed vulnerability class into a **regression gate** (custom Semgrep rule), and stand up the build → scan →
> SBOM → sign pipeline (capstone M2–M3). **Covers:** Labs 7.1, 7.3, 10.1, 10.3, 11.1. **Executed:** 2026-09-26 (Phase 3 kickoff).

---

## Part A: A custom SAST rule for the SQLi class (Lab 7.3, F-016)

The audit found SQL built by string interpolation in `login.ts` and `search.ts` (F-016). Fixing those lines isn't enough — the *class*
must be blocked so it can't come back. That's a custom rule, not a generic scanner.

**Rule** ([.semgrep/sequelize-sqli.yaml](../../.semgrep/sequelize-sqli.yaml)): flag any `sequelize.query()` whose SQL is a template literal
with interpolation or a `+` concatenation.

**Tested against the real vulnerable source:**
```bash
semgrep scan --config .semgrep/sequelize-sqli.yaml tmp/juice-shop/routes
# -> 2 Code Findings: routes/login.ts, routes/search.ts   (exactly the two audit hits, nothing else)
```

**Precision proven with a rule self-test** ([.semgrep/sequelize-sqli.ts](../../.semgrep/sequelize-sqli.ts), `// ruleid:` = must fire,
`// ok:` = must not):
```bash
semgrep --test --config .semgrep/sequelize-sqli.yaml .semgrep/sequelize-sqli.ts
# -> 1/1: ✓ All tests passed
```
The parameterised (fixed) form is **not** flagged, so the gate rewards the correct fix instead of banning the API. This is the difference
between a rule that helps and one developers route around.

**Wired into the gate** (step 3/7 of [security-scan.sh](../../scripts/security-scan.sh)): it runs the self-test *and* scans the repo, so
the rule's own correctness is enforced and any matching app code fails CI.

## Part B: Build → scan → SBOM → sign pipeline (Labs 10.1/10.3, capstone M2–M3)

[.github/workflows/build-sign.yml](../../.github/workflows/build-sign.yml) implements the supply-chain mechanism:
1. **Build** our own image from `build/Dockerfile` and push to **GHCR** (our registry: closes EXC-006).
2. **Scan** it with Trivy; fail on fixable HIGH/CRITICAL (F-017 gate).
3. **SBOM** with Syft (CycloneDX) — the "do we ship library X?" answer (Lab 10.1).
4. **Sign** keylessly with Cosign (Sigstore/OIDC) and attest the SBOM (Lab 10.3).
5. The existing [Kyverno verify-image-signatures policy](../../platform/kyverno/cluster-only/verify-image-signatures.yaml) then admits
   only images signed by this workflow (capstone M5).

> **Status:** the workflow is written, pinned by commit SHA, and lints clean (`semgrep p/github-actions`). It **activates** when:
> (a) a Juice Shop **fork with fixes** is added at `build/` (rotating the F-013/F-015 keys and fixing F-016), and
> (b) the repo has `packages: write` + Cosign OIDC enabled. Until then it's guarded and skipped. This is the path that finally
> **resolves** F-013/F-015 (rotated keys in our own build) and closes EXC-006.

---

## Lab 7 exit checklist
- [x] Custom Semgrep rule catches the F-016 SQLi class on the real source (2/2 hits, no false positives)
- [x] Rule self-test (`semgrep --test`) passes and is part of the gate, so the rule can't silently rot
- [x] Parameterised code proven to pass — the gate rewards the fix
- [x] SAST step added to the security gate (now 7 steps)
- [x] Build/scan/SBOM/sign workflow written, SHA-pinned and lint-clean (activates with the fork)

**Interview takeaway:** "How do you stop a vulnerability class from recurring?" Write a precise custom SAST rule, prove it with a self-test
(fires on the bug, passes the fix), and gate it in CI — then back it with SBOMs and signed images so the whole supply chain is verifiable.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L7-ISSUE-1 | `semgrep --test` failed: "rule id mismatch" | A header comment contained the text `ruleid:`, which the test parser read as an annotation | Keep `ruleid:`/`ok:` tokens out of test-file prose |
| L7-ISSUE-2 | The rule missed a `db.query('...'+x)` case | The first patterns only covered `sequelize.query` with a 2nd arg | Scope the rule to the real sink (`sequelize.query`) and cover interpolation + concat, with/without a 2nd arg; align the test |

---
**Lab 7** · [All labs](README.md) · Principles [07](../principles/07-never-trust-input.md), [10](../principles/10-supply-chain-integrity.md), [11](../principles/11-shift-left-automation.md) · [← Lab 6](lab-06-virtual-patch-proxy.md)
