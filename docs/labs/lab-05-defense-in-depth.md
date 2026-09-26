# Lab 5: Defence in Depth — NetworkPolicy + Pod Security (Execution Guide)
**Lab 5** · [All labs](README.md) · [Principle 04](../principles/04-defense-in-depth.md) · [← Lab 4](lab-04-least-privilege.md)

> **Goal:** stop east-west traffic with a default-deny NetworkPolicy, and make the cluster **enforce** the hardening from Lab 4 with
> Pod Security Admission. **Covers:** Labs 4.1 (NetworkPolicy) and 4.2 (Pod Security). **Closes:** F-003, F-004. **Time:** ~1 h. **Executed:** 2026-09-26.

---

## Part A: Default-deny networking (Lab 4.1, F-003)

### Baseline: the network is flat
```bash
kubectl create ns nettest
kubectl -n nettest run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600
kubectl -n nettest exec probe -- wget -qO- --timeout=5 http://juice-shop.juice-shop.svc:3000/rest/admin/application-version
# -> {"version":"20.2.0"}   a pod in ANOTHER namespace can reach the app (F-003)
```
CNI: **kindnet**, which enforces NetworkPolicy in this kind version.

### Apply default-deny + a narrow allow
[platform/network/juice-shop-netpol.yaml](../../platform/network/juice-shop-netpol.yaml): one policy denies all ingress and egress for
the namespace; a second allows only what the app needs.
```yaml
# allow-app ingress: only same-namespace pods, only port 3000
ingress:
  - from: [{podSelector: {}}]
    ports: [{port: 3000, protocol: TCP}]
# egress: DNS only
egress:
  - to: [{namespaceSelector: {}, podSelector: {matchLabels: {k8s-app: kube-dns}}}]
    ports: [{port: 53, protocol: UDP}, {port: 53, protocol: TCP}]
```

### Verify: east-west blocked, the app still works
```bash
kubectl -n nettest exec probe -- wget -qO- --timeout=5 http://juice-shop.juice-shop.svc:3000/...   # download timed out (BLOCKED)
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/rest/admin/application-version        # 200 (port-forward is node-sourced)
kubectl -n juice-shop get pod -l app=juice-shop                                                      # 1/1 Running (readiness probe still passes)
```

| Path | Before | After |
|---|---|---|
| Pod in another namespace → app:3000 | reachable | **timed out (blocked)** |
| `kubectl port-forward` → app | 200 | 200 (node-sourced, exempt) |
| Kubelet readiness probe | passes | passes (node-sourced, exempt) |

**Key insight:** a NetworkPolicy with only `ports:` (no `from:`) allows that port from **any** source — the first attempt didn't block
anything. Restricting `from:` to the same namespace is what actually stops east-west traffic. Node-originated traffic (kubelet probes,
port-forward) is not affected by pod NetworkPolicies, so the app keeps working.

## Part B: Enforce Pod Security "restricted" (Lab 4.2, F-004)

Roll out in stages so nothing breaks by surprise:
```bash
# 1. warn + audit first: re-apply and read any warnings (they're the to-do list)
kubectl label ns juice-shop pod-security.kubernetes.io/warn=restricted pod-security.kubernetes.io/audit=restricted --overwrite
kubectl apply -f apps/juice-shop/juice-shop.yaml     # NO warnings -> the Lab 4 hardening already meets restricted
# 2. enforce
kubectl label ns juice-shop pod-security.kubernetes.io/enforce=restricted --overwrite
```
The labels are committed on the Namespace in [the manifest](../../apps/juice-shop/juice-shop.yaml), so enforcement is declarative, not a
one-off command.

### Verify: a non-compliant pod is rejected at admission
```bash
kubectl -n juice-shop run bad --image=busybox:1.37 --privileged --command -- sleep 60
```
```
Error from server (Forbidden): pods "bad" is forbidden: violates PodSecurity "restricted:latest":
privileged (...), allowPrivilegeEscalation != false (...), unrestricted capabilities (...),
runAsNonRoot != true (...), seccompProfile (...)
```
Even if someone bypassed CI, the cluster itself now refuses an unsafe pod. That's the difference between hardening that's *applied* (Lab 4)
and hardening that's *enforced* (this lab): **preventive control backed by an admission control**.

## Findings closed
| Finding | Was | Now | Evidence |
|---|---|---|---|
| F-003 | flat pod network | **Fixed** | default-deny + narrow allow; cross-namespace probe times out |
| F-004 | hardening not enforced | **Fixed** | namespace enforces `restricted`; privileged pod rejected |

---

## Lab 5 exit checklist
- [x] Confirmed the flat network, then blocked it with default-deny + a same-namespace/port-3000 allow
- [x] Verified east-west is blocked while the app, port-forward and readiness probe still work
- [x] Rolled out Pod Security warn → audit → enforce; the hardened pod passed with no warnings
- [x] Proved a privileged pod is rejected at admission
- [x] Both controls declarative in Git (Namespace labels, NetworkPolicy in `make deploy`)

**Interview takeaway:** "How do you limit lateral movement in Kubernetes?" Default-deny NetworkPolicy with narrow allows, plus Pod Security
`restricted` enforced at admission, and know why node-sourced traffic (probes, port-forward) is exempt.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L5-ISSUE-1 | After the first policy, the cross-namespace probe still connected | An ingress rule with only `ports:` and no `from:` allows that port from all sources | Add a `from:` selector to actually restrict sources |
| L5-ISSUE-2 | Worried the port-forward/readiness probe would break under default-deny | Those originate from the node (kubelet), not from a pod | Pod NetworkPolicies don't govern node-sourced traffic; verify rather than assume |

---
**Lab 5** · [All labs](README.md) · [Principle 04](../principles/04-defense-in-depth.md) · [← Lab 4](lab-04-least-privilege.md)
