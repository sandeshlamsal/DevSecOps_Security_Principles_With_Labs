# 09: Protect Data and Secrets

> "Encrypt in transit, encrypt at rest, and never let a secret touch Git."

## In plain words
- **In transit:** TLS everywhere, including between internal services where you can (mTLS).
- **At rest:** disks, databases and backups encrypted, with keys managed by a KMS and not stored next to the data.
- **Secrets** (API keys, DB passwords, signing keys, tokens) live in a secrets manager (Vault, a cloud secrets manager,
  External Secrets / Sealed Secrets for Kubernetes). They're injected at runtime, rotated, and **never committed**.
- **Hashing ≠ encryption ≠ encoding.** Hashing is one-way (passwords, integrity). Encryption is two-way with a key.
  Encoding (Base64) is **not security at all**, and Kubernetes Secrets are only Base64-encoded by default.

## Why it matters
- **Uber (2016):** engineers stored cloud access keys in a private code repository. Attackers accessed the repository, used
  the keys, and downloaded data on 57 million users and drivers.
- Public-repo secret leaks are so common that GitHub now scans for and revokes many key types automatically. Leaked keys are
  often used by automated bots within minutes of being pushed.

## In our lab
Juice Shop's source deliberately contains hard-coded secrets. Our own repo must stay clean, and CI will enforce that.

## Hands-on labs

### Lab 9.1: Scan for secrets ⏳
1. Install gitleaks (`brew install gitleaks`).
2. Scan the Juice Shop source: `gitleaks dir tmp/juice-shop --report-path reports/gitleaks-juice-shop.json`, and triage the results
   (real secret, test fixture or false positive?).
3. Scan **this** repo's history: `gitleaks git .`. It should be clean. Keep it that way.

### Lab 9.2: A secret done right in Kubernetes ⏳
1. Create a Secret with `kubectl create secret generic ...` (never a YAML file in Git).
2. Show that `kubectl get secret -o yaml` only Base64-encodes it, and explain who can read it (RBAC `get secrets`).
3. Enable and explain encryption at rest for Secrets in etcd (read the kind/kubeadm config, and describe what changes in a managed cloud cluster).

### Lab 9.3: Respond to a leaked secret ⏳
Simulate committing a fake API key on a throwaway branch. Write the runbook: **1. revoke/rotate first**, 2. check where it was used,
3. remove it from history, 4. add a pre-commit hook. Explain why step 1 comes before step 3.

## Best-practice checklist
- [ ] Secret scanning runs as a pre-commit hook **and** in CI, on the full history
- [ ] Secrets come from a manager, are rotated automatically, and are scoped per service
- [ ] Kubernetes Secrets are encrypted at rest and readable by few identities
- [ ] Data is classified; sensitive fields are minimised, masked in logs and encrypted
- [ ] Leaked secrets are treated as incidents: rotate first, then clean up

## Interview questions
1. Hashing vs encryption vs encoding: when do you use each?
2. A developer pushed an AWS key to a public repo 10 minutes ago. What do you do, in order?
3. Are Kubernetes Secrets secure? What would you add?
4. What is envelope encryption, and why do KMSs use it?
5. How would you roll out secret scanning to 200 repos without blocking everyone on day one?
