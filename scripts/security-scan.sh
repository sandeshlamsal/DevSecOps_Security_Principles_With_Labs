#!/usr/bin/env bash
# Security gates. Runs the SAME way locally (`make security-scan`) and in GitHub Actions (.github/workflows/security.yml).
# Every gate is blocking. Known debt is handled as expiring exceptions (SECURITY-EXCEPTIONS.md), never by turning a gate off.
# Tools: gitleaks, semgrep, trivy, checkov, kyverno (versions pinned in the workflow).
set -euo pipefail
cd "$(dirname "$0")/.."
step(){ echo; echo "==> $*"; }

step "1/7 Secrets: gitleaks over the full git history (F-010/F-013/F-015 class)"
gitleaks git . --redact --no-banner --exit-code 1
# ...and uncommitted changes, so running this BEFORE `git commit` catches what CI would (a gap found 2026-09-26)
gitleaks git --staged --redact --no-banner --exit-code 1

step "2/7 CI supply chain: Semgrep GitHub Actions rules (F-023 class: unpinned actions, script injection)"
semgrep scan --config p/github-actions --metrics=off --error --quiet .github/

step "3/7 SAST: custom app rules self-test + scan (regression gate for F-016 SQLi)"
semgrep --test --config .semgrep/ .semgrep/ >/dev/null    # prove the custom rules still work
semgrep scan --config .semgrep/ --metrics=off --error --quiet \
  --exclude .semgrep --exclude tmp .                        # fail on any matching app code in the repo

step "4/7 Kubernetes misconfiguration: Trivy config on apps/ (exceptions: .trivyignore, each with exp: date)"
trivy config --quiet --exit-code 1 apps/
trivy config --quiet --exit-code 1 platform/proxy/

step "5/7 Infrastructure as code: Checkov on infra/azure (exceptions: inline checkov:skip with EXC-nnn)"
checkov -d infra/azure --skip-download --framework terraform --var-file infra/azure/terraform.tfvars.example --quiet --compact

step "6/7 Exceptions register: none expired, none undocumented"
python3 scripts/check-exceptions.py

step "7/7 Admission policies (Kyverno CLI, offline): REPORT ONLY until capstone M5, then blocking"
kyverno apply platform/kyverno/policies/ --resource apps/juice-shop/juice-shop.yaml 2>/dev/null | grep -E '^(pass|policy)' || true

echo; echo "SECURITY GATES: ALL BLOCKING CHECKS PASSED"
