#!/usr/bin/env bash
# Run the triage scanners against a target directory (and optionally an image) and save raw JSON.
# Usage: run-scanners.sh <target-dir> [--image <image-ref>] [--out <dir>]
# Deterministic part of the security-triage skill: it never judges findings, it only collects them.
set -uo pipefail

TARGET="${1:?usage: run-scanners.sh <target-dir> [--image IMAGE] [--out DIR]}"; shift
IMAGE=""; OUT="reports/triage/$(date +%Y%m%d-%H%M%S)"
while [ $# -gt 0 ]; do
  case "$1" in
    --image) IMAGE="$2"; shift 2 ;;
    --out)   OUT="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -d "$TARGET" ] || { echo "target is not a directory: $TARGET" >&2; exit 2; }
mkdir -p "$OUT"
SEMGREP_CONFIGS="${SEMGREP_CONFIGS:-p/owasp-top-ten}"   # override, e.g. "p/owasp-top-ten p/nodejs"

have(){ command -v "$1" >/dev/null 2>&1; }
ran=(); skipped=()

if have semgrep; then
  args=(); for c in $SEMGREP_CONFIGS; do args+=(--config "$c"); done
  semgrep scan "${args[@]}" --metrics=off --quiet --json -o "$OUT/semgrep.json" "$TARGET" >/dev/null 2>&1
  ran+=("semgrep ($SEMGREP_CONFIGS)")
else skipped+=("semgrep: pip install semgrep"); fi

if have gitleaks; then
  gitleaks dir "$TARGET" --redact --no-banner --exit-code 0 --report-format json --report-path "$OUT/gitleaks.json" >/dev/null 2>&1
  ran+=("gitleaks")
else skipped+=("gitleaks: brew install gitleaks"); fi

if have trivy; then
  trivy fs --quiet --scanners vuln --severity HIGH,CRITICAL --format json -o "$OUT/trivy-fs.json" "$TARGET" >/dev/null 2>&1
  trivy config --quiet --format json -o "$OUT/trivy-config.json" "$TARGET" >/dev/null 2>&1   # one directory per call
  ran+=("trivy fs (deps)" "trivy config (IaC/K8s)")
  if [ -n "$IMAGE" ]; then
    trivy image --quiet --severity HIGH,CRITICAL --format json -o "$OUT/trivy-image.json" "$IMAGE" >/dev/null 2>&1
    ran+=("trivy image ($IMAGE)")
  fi
else skipped+=("trivy: brew install trivy"); fi

if have checkov; then
  # --skip-download: no call-home to the vendor API when scanning local files
  checkov -d "$TARGET" --skip-download --quiet --compact -o json > "$OUT/checkov.json" 2>/dev/null
  ran+=("checkov")
else skipped+=("checkov: pipx install checkov"); fi

echo "reports: $OUT"
for r in "${ran[@]}"; do echo "  ran      $r"; done
for s in "${skipped[@]:-}"; do [ -n "$s" ] && echo "  MISSING  $s"; done
