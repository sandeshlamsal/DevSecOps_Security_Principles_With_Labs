# 04: Defence in Depth

> "Assume any single control will fail. Make sure it isn't the only one."

## In plain words
Stack **independent** layers of controls, so an attacker who gets past one still faces the next. Mix the three kinds of control:
**preventive** (stop it), **detective** (notice it) and **corrective** (recover from it).

```
 Internet → [WAF / rate limit] → [TLS + auth] → [app input validation + authz]
          → [container: non-root, read-only] → [Pod Security + NetworkPolicy]
          → [node / cloud isolation] → [encrypted data + backups]
          …and across all of them: [logging → detection → response]
```

The layers must fail **independently**. Two controls that share the same config file or the same credentials are really one layer.

## Why it matters
**Target (2013):** attackers got in through credentials stolen from a heating and ventilation vendor. The network was flat enough
that they could move from that vendor-facing access to the point-of-sale systems, where they collected about 40 million
payment cards. Network segmentation would have been a second layer the stolen credentials alone couldn't cross.

## In our lab
- ❌ **F-003:** there are no NetworkPolicies, so every pod in the cluster can reach every other pod (a flat network).
- ❌ **F-004:** the namespace has no Pod Security Admission labels, so nothing *enforces* the hardening from [03](03-least-privilege.md).
  If someone removes the securityContext later, nothing stops it.

## Hands-on labs

### Lab 4.1: Default-deny networking ⏳
1. Deploy a throwaway client pod in another namespace and confirm it can reach `juice-shop.juice-shop:3000` (it can: flat network).
2. Apply a default-deny NetworkPolicy to `juice-shop`, then allow only the ingress you need.
3. Re-test from the client pod and record the before/after output. (Note: kind's default CNI, kindnet, supports NetworkPolicy
   from kind v0.24+. If a policy has no effect, that's an issue worth logging.)

### Lab 4.2: Enforce Pod Security Standards ⏳
1. Label the namespace in **warn/audit** mode first: `kubectl label ns juice-shop pod-security.kubernetes.io/warn=restricted pod-security.kubernetes.io/audit=restricted`
2. Re-apply the manifest and read the warnings. They're your to-do list.
3. Once it's clean, switch to `enforce=restricted`. Try to deploy a pod that runs privileged, and capture the rejection.

### Lab 4.3: Map the layers ⏳
Draw the layer diagram above **for Juice Shop as it is today**, marking each layer ✅ present, ❌ missing or ⚠️ partial. Revisit it
after Principle 12, where every layer should be in place.

## Best-practice checklist
- [ ] Network segmentation, with default-deny between workloads
- [ ] Hardening is **enforced** by admission policy, not just applied by convention
- [ ] Preventive controls are paired with detective ones (a blocked action is also logged)
- [ ] No single credential or config file controls multiple layers

## Interview questions
1. What is defence in depth? Give layers for a web app running on Kubernetes.
2. Preventive vs detective vs corrective controls: give an example of each.
3. Why roll out a policy in "audit" mode before "enforce" mode?
4. What is lateral movement, and which controls limit it?
5. How does zero trust relate to defence in depth?
