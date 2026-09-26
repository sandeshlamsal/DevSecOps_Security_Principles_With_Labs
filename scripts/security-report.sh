#!/usr/bin/env bash
# Vulnerability REPORTING (not gating): write every scanner's results as SARIF into reports/sarif/,
# which the workflow uploads to GitHub code scanning (repo → Security → Code scanning).
# Gates live in scripts/security-scan.sh; this script never fails the build on findings.
set -uo pipefail
cd "$(dirname "$0")/.."
OUT=reports/sarif; rm -rf "$OUT"; mkdir -p "$OUT"
IMAGE="$(grep -oE 'bkimminich/juice-shop[:@][^ ]+' apps/juice-shop/juice-shop.yaml | head -1)"

gitleaks git . --redact --no-banner --exit-code 0 --report-format sarif --report-path "$OUT/gitleaks.sarif"
semgrep scan --config p/github-actions --metrics=off --quiet --sarif -o "$OUT/semgrep.sarif" .github/
trivy config --quiet --format sarif -o "$OUT/trivy-config.sarif" apps/
checkov -d infra/azure --skip-download --framework terraform --var-file infra/azure/terraform.tfvars.example \
  --quiet -o sarif --output-file-path "$OUT" >/dev/null; mv "$OUT/results_sarif.sarif" "$OUT/checkov.sarif" 2>/dev/null
# The deployed image: reported weekly so NEW CVEs in an unchanged image still surface (F-017).
trivy image --quiet --severity HIGH,CRITICAL --format sarif -o "$OUT/trivy-image.sarif" "$IMAGE"

for f in "$OUT"/*.sarif; do
  printf "%-22s %s results\n" "$(basename "$f")" "$(python3 -c "import json,sys;print(sum(len(r.get('results',[])) for r in json.load(open('$f'))['runs']))")"
done
