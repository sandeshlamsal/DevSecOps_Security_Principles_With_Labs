#!/usr/bin/env bash
# Security gates. Runs the SAME way locally (`make security-scan`) and in GitHub Actions (.github/workflows/security.yml).
# Every gate is blocking. Known debt is handled as expiring exceptions (SECURITY-EXCEPTIONS.md), never by turning a gate off.
# Tools: gitleaks, semgrep, trivy, checkov, kyverno (versions pinned in the workflow).
set -euo pipefail
cd "$(dirname "$0")/.."
step(){ echo; echo "==> $*"; }

step "1/6 Secrets: gitleaks over the full git history (F-010/F-013/F-015 class)"
gitleaks git . --redact --no-banner --exit-code 1
# ...and uncommitted changes, so running this BEFORE `git commit` catches what CI would (a gap found 2026-09-26)
gitleaks git . --pre-commit --redact --no-banner --exit-code 1

step "2/6 CI supply chain: Semgrep GitHub Actions rules (F-023 class: unpinned actions, script injection)"
semgrep scan --config p/github-actions --metrics=off --error --quiet .github/

step "3/6 Kubernetes misconfiguration: Trivy config on apps/ (exceptions: .trivyignore, each with exp: date)"
trivy config --quiet --exit-code 1 apps/

step "4/6 Infrastructure as code: Checkov on infra/azure (exceptions: inline checkov:skip with EXC-nnn)"
checkov -d infra/azure --skip-download --framework terraform --var-file infra/azure/terraform.tfvars.example --quiet --compact

step "5/6 Exceptions register: none expired, none undocumented"
python3 scripts/check-exceptions.py

step "6/6 Admission policies (Kyverno CLI, offline): REPORT ONLY until capstone M5, then blocking"
kyverno apply platform/kyverno/policies/ --resource apps/juice-shop/juice-shop.yaml 2>/dev/null | grep -E '^(pass|policy)' || true

echo; echo "SECURITY GATES: ALL BLOCKING CHECKS PASSED"
