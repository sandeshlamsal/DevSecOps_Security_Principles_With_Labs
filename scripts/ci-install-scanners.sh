#!/usr/bin/env bash
# Install pinned scanners on a Linux CI runner. Every binary is verified against its published SHA-256 checksum.
# Versions come from the workflow env (single source of truth).
set -euo pipefail
: "${GITLEAKS_VERSION:?}" "${TRIVY_VERSION:?}" "${KYVERNO_VERSION:?}" "${SEMGREP_VERSION:?}" "${CHECKOV_VERSION:?}"
BIN="${RUNNER_TEMP:-/tmp}/bin"; mkdir -p "$BIN"; cd "${RUNNER_TEMP:-/tmp}"
verify_and_extract(){  # url_of_tarball url_of_checksums binary_name
  local tgz sums; tgz="$(basename "$1")"; sums="$3.sums"
  curl -sSLf -o "$tgz" "$1"; curl -sSLf -o "$sums" "$2"
  echo "$(grep " ${tgz}\$" "$sums" | cut -d' ' -f1)  $tgz" | sha256sum -c -
  tar -xzf "$tgz" -C "$BIN" "$3"
}
verify_and_extract "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
                   "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_checksums.txt" gitleaks
verify_and_extract "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
                   "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_checksums.txt" trivy
verify_and_extract "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/kyverno-cli_${KYVERNO_VERSION}_linux_x86_64.tar.gz" \
                   "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/checksums.txt" kyverno
python -m pip install --quiet "semgrep==${SEMGREP_VERSION}" "checkov==${CHECKOV_VERSION}"
[ -n "${GITHUB_PATH:-}" ] && echo "$BIN" >> "$GITHUB_PATH"
echo "scanners installed in $BIN"
