#!/usr/bin/env bash
# CI checks. Runs the SAME way locally (`make ci`) and in GitHub Actions (.github/workflows/ci.yml).
# Later phases add security gates here (SAST, secrets, SCA, image scan, policy).
set -euo pipefail
cd "$(dirname "$0")/.."
step(){ echo; echo "==> $*"; }

step "1/2 kubeconform: our manifests"
# platform/kind/cluster.yaml is a kind config, not a Kubernetes resource, so it is not validated here
kubeconform -strict -summary -kubernetes-version 1.35.0 apps/

step "2/2 Docs: markdown links"
python3 scripts/check-links.py

echo; echo "CI: ALL CHECKS PASSED"
