# Lab 4: Least Privilege — Hardening the Pod (Execution Guide)
**Lab 4** · [All labs](README.md) · [Principle 03](../principles/03-least-privilege.md) · [← Lab 3](lab-03-attack-surface-and-defaults.md)

> **Goal:** turn the deliberately unhardened Juice Shop manifest into one that passes `trivy config` clean and would pass Pod
> Security `restricted`, without breaking the app. **Covers:** Labs 3.1 (SA token), 3.2 (securityContext), 3.3 (RBAC). Plan step **A1**.
> **Closes:** F-001, F-002, F-009, F-021. **Time:** ~1.5 h. **Executed:** 2026-09-26.

---

## Step 1: Find what the app writes (before setting a read-only FS)
```bash
grep -rhoE "'(ftp|uploads|logs|frontend/dist)[^']*'|data/juiceshop.sqlite" tmp/juice-shop/server.ts tmp/juice-shop/routes/*.ts | sort -u
```
Juice Shop writes into its **own served app directory**: `frontend/dist`, `ftp`, `logs`, `uploads`, and the SQLite file under `data/`.
A blanket `readOnlyRootFilesystem: true` would break it, and mounting `emptyDir` over those paths would hide the app's own files.
**Decision:** apply every other `restricted` control and leave the root FS writable. It isn't required by Pod Security `restricted`
(Trivy's KSV-0014 is stricter). Trivy still flags it HIGH, so it's a **time-boxed, documented exception (EXC-007)** with a compensating
control, not a silent skip.

## Step 2: The hardened manifest (Labs 3.1 + 3.2)
Key changes in [apps/juice-shop/juice-shop.yaml](../../apps/juice-shop/juice-shop.yaml):
```yaml
# a dedicated ServiceAccount with NO API token (F-001)
automountServiceAccountToken: false
# pod-level:
securityContext: {runAsNonRoot: true, runAsUser: 65532, runAsGroup: 65532, seccompProfile: {type: RuntimeDefault}}
# container-level (F-002):
securityContext: {allowPrivilegeEscalation: false, capabilities: {drop: ["ALL"]}}
# F-009: digest pin
image: bkimminich/juice-shop:v20.2.0@sha256:8739101ade29358abb5469ee66ae78e582c97ed0a5543a4ad102e5fa5193526b
# F-021: CPU limit
resources: {limits: {cpu: "1", memory: 512Mi}}
```
```bash
kubectl apply -f apps/juice-shop/juice-shop.yaml
kubectl -n juice-shop rollout status deploy/juice-shop --timeout=180s   # successfully rolled out
```

## Step 3: Verify every control (Lab 3.1 + 3.2)
```bash
kubectl -n juice-shop get pod -l app=juice-shop -o json | python3 -c "..."   # see below
curl -s -o /dev/null -w 'app: %{http_code}\n' http://127.0.0.1:3000/rest/admin/application-version   # 200
trivy config --quiet apps/                                                    # 0 misconfigurations
```
Result:
```
serviceAccount: juice-shop
automountServiceAccountToken: False
pod securityContext: {runAsNonRoot: True, runAsUser: 65532, runAsGroup: 65532, seccompProfile: RuntimeDefault}
container securityContext: {allowPrivilegeEscalation: False, capabilities: {drop: [ALL]}}
cpu/mem limits: {cpu: 1, memory: 512Mi}
SA-token volumeMounts: NONE (good)
status: Running True
app: 200
Trivy config: 0 misconfigurations
```
The 13-rule EXC-005 suppression was **retired**; the hardened manifest passes on its own merits. Two scoped exceptions remain, each with a
compensating control and an expiry: **EXC-006** (runs the upstream Docker Hub image; trusted-registry enforced in Phase 3 via our own GHCR
build + Kyverno) and **EXC-007** (read-only root FS, see above). Reaching zero *unmanaged* flags — not zero findings — was the target from
[REMEDIATION.md §2](../../findings/REMEDIATION.md#2-what-zero-security-flags-means-here).

## Step 4: RBAC review (Lab 3.3)
```bash
SA=system:serviceaccount:juice-shop:juice-shop
kubectl auth can-i --list --as=$SA -n juice-shop     # only default discovery: /api, /healthz, selfsubject*
kubectl auth can-i get secrets --as=$SA -n juice-shop   # no
kubectl auth can-i list pods   --as=$SA -n juice-shop   # no
kubectl auth can-i get nodes   --as=$SA                 # no
```
The dedicated service account has **only** the default API-discovery permissions: no secrets, no pods, no nodes. Combined with the token
no longer being mounted (Step 3), a compromise of the app process gains nothing against the Kubernetes API. That's least privilege and a
smaller [blast radius](../principles/03-least-privilege.md).

## Findings closed

| Finding | Was | Now | Evidence |
|---|---|---|---|
| F-001 | default SA, token mounted | **Fixed** | dedicated SA, `automountServiceAccountToken: false`, no token volumeMount |
| F-002 | no securityContext | **Fixed** | runAsNonRoot, drop ALL caps, no privilege escalation, seccomp RuntimeDefault |
| F-009 | image pinned by tag | **Fixed** | pinned by `@sha256:` digest |
| F-021 | no CPU limit | **Fixed** | `limits.cpu: "1"` |

## Documented exceptions (EXC-006, EXC-007)
- **EXC-006 (registry):** the deployment runs the pinned **upstream** image from Docker Hub, which Trivy treats as untrusted (KSV-0125). Deliberate for now; the trusted-registry control is enforced in Phase 3 by building our own signed image to GHCR + the Kyverno registry policy.
- **EXC-007 (read-only root FS):** the app writes into its served directory, so `readOnlyRootFilesystem` breaks it. Not required by Pod Security `restricted`. Compensating: non-root, all caps dropped, no privilege escalation, seccomp. Revisit with scoped `emptyDir` mounts over `logs/`, `uploads/` and `data/`.

Both are in [SECURITY-EXCEPTIONS.md](../../SECURITY-EXCEPTIONS.md) with an owner and expiry; CI fails if either expires.

---

## Lab 4 exit checklist
- [x] Dedicated ServiceAccount, API token not mounted (F-001)
- [x] Non-root, all capabilities dropped, no privilege escalation, seccomp RuntimeDefault (F-002)
- [x] Image pinned by digest (F-009); CPU limit set (F-021)
- [x] App still returns 200 after hardening
- [x] `trivy config` gate green; EXC-005 (13 rules) retired; 2 scoped exceptions remain (EXC-006 registry, EXC-007 read-only FS)
- [x] Service account proven to have no access to secrets/pods/nodes (F-... blast radius)

**Interview takeaway:** "Harden a Kubernetes workload." Walk through the securityContext line by line, explain why the token mount and root
matter, and show you verified the result with `trivy config` and `kubectl auth can-i` rather than assuming.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L4-ISSUE-1 | `readOnlyRootFilesystem: true` would break the app | Juice Shop writes into its own served app directory | Learn the app's write paths before enforcing a read-only FS; scope `emptyDir` mounts, don't blanket-enable |
| L4-ISSUE-2 | `curl` returned `000` right after rollout | The port-forward binds to one pod and dies when that pod is replaced | Restart `make open` after any rollout (same as L1-ISSUE-2) |

---
**Lab 4** · [All labs](README.md) · [Principle 03](../principles/03-least-privilege.md) · [← Lab 3](lab-03-attack-surface-and-defaults.md)
