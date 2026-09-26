# Lab 11: Security Incident Game Day (Execution Guide)
**Lab 11** · [All labs](README.md) · [Principle 12](../principles/12-assume-breach.md) · [← Lab 10](lab-10-runtime-detection.md)

> **Goal:** run the full incident lifecycle end to end — detect (Falco) → analyse → contain → eradicate → recover → blameless postmortem
> (Lab 12.3). **Deliverable:** [incidents/2026-09-26-gd1-intruder-credential-read.md](../../incidents/2026-09-26-gd1-intruder-credential-read.md). **Executed:** 2026-09-26.

---

## Scenario
An attacker has `exec` on a pod in the `default` namespace (a common foothold). They read the credential store and try to move laterally to
the shop. Do the controls detect it, and can it be contained?

## The run
```bash
kubectl run intruder --image=busybox:1.37 --command -- sleep 600
kubectl exec intruder -- sh -c "cat /etc/shadow >/dev/null"                                  # attacker action 1
kubectl exec intruder -- wget -qO- --timeout=5 http://juice-shop.juice-shop.svc:3000/...     # attacker action 2 (lateral)
```
| Step | Result |
|---|---|
| Lateral movement to the app | **BLOCKED / timeout** — the Lab 5 NetworkPolicy stopped it |
| Falco detection | **Fired** — sensitive-file read on `pod=intruder ns=default`, MITRE T1003.008 |

## The response
```bash
# ANALYSE: preserve evidence before changing anything
kubectl get pod intruder -o jsonpath='{.metadata.creationTimestamp} node={.spec.nodeName} image=...'  > evidence.txt
# CONTAIN: quarantine with a deny-all NetworkPolicy, then verify isolation
kubectl label pod intruder quarantine=true
kubectl apply -f - <<'YAML'   # NetworkPolicy selecting quarantine=true, deny all ingress+egress
...
YAML
kubectl exec intruder -- nslookup juice-shop...    # ";; connection timed out" -> isolated
# ERADICATE + RECOVER
kubectl delete pod intruder
curl .../rest/admin/application-version            # 200 -> shop healthy
```

## What the game day proved
- **Prevention limited the blast radius**: the compromised pod couldn't reach the app (segmentation), and the app itself is non-root with no
  SA token (Labs 4–5), so the same attack there would gain little.
- **Detection worked**: the read was flagged with full attribution in seconds (Lab 10).
- **Response was fast** because the quarantine pattern (label + deny-all policy) was ready in advance.

## Action items (the point of a game day: it improves the system)
| # | Gap found | Action | Principle |
|---|---|---|---|
| A1 | `default` ns has no default-deny policy | Add cluster-wide default-deny | [04](../principles/04-defense-in-depth.md) |
| A2 | No Kubernetes audit log ("who created the pod?") | Do [Lab 12.2](../principles/12-assume-breach.md) (API audit policy) | [12](../principles/12-assume-breach.md) |
| A3 | Falco alerts only in pod logs | Route to SIEM/Slack (falcosidekick) | [12](../principles/12-assume-breach.md) |
| A4 | Only `juice-shop` enforces Pod Security | Enforce `restricted` cluster-wide | [04](../principles/04-defense-in-depth.md) |

Full write-up with timeline: [the incident report](../../incidents/2026-09-26-gd1-intruder-credential-read.md).

---

## Lab 11 exit checklist
- [x] Ran a realistic scenario against the live, hardened cluster
- [x] Detection fired (Falco) and lateral movement was blocked (NetworkPolicy)
- [x] Followed detect → analyse → contain → eradicate → recover, preserving evidence first
- [x] Blameless postmortem with 4 action items, each mapped to a principle

**Interview takeaway:** "Walk me through responding to a container intrusion." Detect (runtime alert) → analyse and preserve evidence →
contain (isolate, don't tip off) → eradicate → recover → blameless postmortem whose action items become new controls. And note that
prevention (segmentation, least privilege) is what keeps a foothold from becoming a breach.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L11-ISSUE-1 | The attacker pod reached out but was blocked | juice-shop's ingress policy denied it, but `default` ns itself had no egress policy | Segmentation must cover every namespace, not just the sensitive one (action A1) |

---
**Lab 11** · [All labs](README.md) · [Principle 12](../principles/12-assume-breach.md) · [← Lab 10](lab-10-runtime-detection.md)
