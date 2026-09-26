# Lab 6: Virtual Patch — Reverse Proxy for the Critical Finding (Execution Guide)
**Lab 6** · [All labs](README.md) · [Principle 05](../principles/05-attack-surface-reduction.md) · [← Lab 5](lab-05-defense-in-depth.md)

> **Goal:** stop the Critical/High **exposed-path** findings at the edge with a hardened reverse proxy (plan step **B1**), without
> changing the app. **Closes exposure for:** F-005, F-006, F-014; **blocks exposure but rotation still needed for** F-013, F-015.
> **Time:** ~1.5 h. **Executed:** 2026-09-26.

---

## Why a virtual patch
The audit's worst finding, **F-013**, is a private key downloadable at `/infrastructure/terraform/networking.tf`. The real fix is to stop
shipping it and **rotate the key** (plan C2) — but that needs our own rebuilt image (Phase 3). Meanwhile the exposure is live. A **virtual
patch** blocks the attack at a layer we control **now**, then the durable fix follows. Both, in order, is what real teams do.

## Step 1: A hardened reverse proxy
[platform/proxy/](../../platform/proxy/): an **unprivileged** nginx (so it passes the `restricted` policy from [Lab 5](lab-05-defense-in-depth.md))
that proxies to the app and refuses the sensitive paths:
```nginx
server_tokens off;
location ~ ^/(ftp|infrastructure|encryptionkeys|support/logs|metrics)(/|$) { return 404; }
location / { proxy_pass http://juice-shop.juice-shop.svc:3000; ... }
```
The pod is hardened like the app **and** runs read-only-root with `emptyDir` mounts for nginx's writable paths (`/tmp`, `/var/cache/nginx`),
image digest-pinned:
```yaml
securityContext: {runAsNonRoot: true, runAsUser: 101, ..., seccompProfile: {type: RuntimeDefault}}
containers: [{securityContext: {allowPrivilegeEscalation: false, capabilities: {drop: [ALL]}, readOnlyRootFilesystem: true}}]
```
A [NetworkPolicy](../../platform/network/juice-shop-netpol.yaml) `allow-proxy` lets it receive :8080 and reach the app on :3000 + DNS.

## Step 2: Verify the block
```bash
kubectl port-forward -n juice-shop svc/juice-shop-proxy 3000:8080   # entry is now the proxy
```
| Path | Direct to app (before) | Via proxy (after) |
|---|---|---|
| `/` , `/api/Products` | 200 | **200** |
| `/ftp`, `/ftp/legal.md` | 200 | **404** |
| `/encryptionkeys/premium.key` | 200 | **404** |
| `/support/logs` | 200 | **404** |
| `/metrics` | 200 | **404** |
| `/infrastructure/terraform/networking.tf` (**the private key**) | 200 | **404** |

`make open` now port-forwards the **proxy**, so the app is reached the secure way by default.

## Step 3: Honest status of each finding

| Finding | Status after B1 | Why |
|---|---|---|
| F-005 `/ftp` | **Mitigated** | internal docs no longer reachable |
| F-006 `/metrics` | **Mitigated** | blocked |
| F-014 `/support/logs` | **Mitigated** | blocked |
| F-013 private key | 🟡 **Exposure blocked, rotation still required** | the key was already public upstream; it must be rotated (C2, Phase 3) |
| F-015 `premium.key` | 🟡 **Exposure blocked, rotation still required** | same reason |

**Key lesson:** a virtual patch stops *new* access, but anything already leaked stays leaked. F-013/F-015 are not "done" until the keys are
**rotated**. Marking them Fixed now would be dishonest — and a real auditor would catch it.

## Caveat
The block only helps if traffic goes **through** the proxy. The app Service (`juice-shop:3000`) is still directly reachable **inside** the
namespace; the NetworkPolicy limits that to same-namespace pods, and nothing outside the cluster reaches it (localhost-only). In production
you'd make the proxy the only ingress path and forbid direct routes.

---

## Lab 6 exit checklist
- [x] Hardened, unprivileged reverse proxy deployed (passes Pod Security `restricted`)
- [x] Sensitive paths return 404 through the proxy; app and API still work
- [x] Proxy manifest passes `trivy config` (digest-pinned, read-only root FS; LOW uid exception EXC-008)
- [x] `make open` repointed to the proxy
- [x] Findings updated honestly: F-005/006/014 Mitigated; F-013/015 exposure-blocked but rotation pending

**Interview takeaway:** "You find a live secret exposed in production and the code fix will take days. What do you do?" Virtual-patch the
exposure at the proxy/WAF **today**, rotate the secret (assume it's compromised), then fix the code — and don't mark it resolved until the
secret is rotated.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L6-ISSUE-1 | `trivy config apps/ platform/proxy/` printed usage help and exit 1 | `trivy config` takes a **single** directory | Scan each directory in its own invocation |
| L6-ISSUE-2 | nginx wouldn't be able to run read-only-root by default | It writes to `/tmp` and `/var/cache/nginx` | Mount `emptyDir` on exactly those paths; keep the rest read-only |

---
**Lab 6** · [All labs](README.md) · [Principle 05](../principles/05-attack-surface-reduction.md) · [← Lab 5](lab-05-defense-in-depth.md)
