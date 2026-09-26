#!/usr/bin/env bash
# CI checks. Runs the SAME way locally (`make ci`) and in GitHub Actions (.github/workflows/ci.yml).
# Later phases add security gates here (SAST, secrets, SCA, image scan, policy).
set -euo pipefail
cd "$(dirname "$0")/.."
step(){ echo; echo "==> $*"; }

step "1/3 kubeconform: our manifests"
# platform/kind/cluster.yaml is a kind config, not a Kubernetes resource, so it is not validated here
kubeconform -strict -summary -kubernetes-version 1.35.0 apps/

step "2/3 kubeconform: custom resources (Argo CD, Kyverno) via the datree CRD schema catalog"
kubeconform -strict -summary -kubernetes-version 1.35.0 -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  gitops/ platform/kyverno/

step "3/3 Docs: markdown links + every page listed in INDEX.md"
python3 scripts/check-links.py

echo; echo "CI: ALL CHECKS PASSED"
