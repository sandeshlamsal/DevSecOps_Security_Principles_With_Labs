# Security incident: GD-1 — credential-store read from a compromised pod (game day)

- **Severity:** SEV2 (contained, no data exfiltrated)   **Incident commander:** sandesh   **Scribe:** sandesh
- **Type:** Game day (simulated). **Declared (UTC):** 2026-09-26 23:42   **Contained:** 23:43   **Resolved:** 23:44

## Timeline (UTC)
| Time | Event / action | Who |
|---|---|---|
| 23:42:14 | Attacker-controlled pod `intruder` (busybox) running in `default` (simulated foothold) | scenario |
| 23:42:15 | Attacker runs `cat /etc/shadow` in the container | scenario |
| 23:42:15 | Attacker attempts lateral movement to `juice-shop.juice-shop:3000` | scenario |
| 23:42:15 | **Lateral movement BLOCKED** (timeout) by the default-deny NetworkPolicy (Lab 5) | control |
| 23:42:~ | **Falco alert:** "Sensitive file opened for reading by non-trusted program" on pod=intruder | detection |
| 23:43 | Evidence preserved (pod spec: node, image, SA, timestamps) | IC |
| 23:43 | Pod quarantined with a deny-all NetworkPolicy; DNS/egress confirmed cut off | IC |
| 23:44 | Pod eradicated; app confirmed healthy (200) | IC |

## 1. Detect & analyse
- **Detection:** Falco (Lab 10), rule *Sensitive file opened for reading by non-trusted program*, MITRE **T1003.008**.
- **Scope:** one pod (`intruder`, `default` ns, `busybox:1.37`, `default` SA). No access to the app: the NetworkPolicy blocked it.
- **Evidence preserved before change:** `intruder-evidence.txt` (creationTimestamp, node=secops-lab-worker, image, serviceAccount).

## 2. Contain
- Labelled the pod `quarantine=true` and applied a deny-all NetworkPolicy selecting that label.
- Verified isolation: DNS lookup from the pod timed out (egress cut).

## 3. Eradicate & recover
- Deleted the pod (evidence already captured). Removed the quarantine policy.
- Verified the shop still serves (HTTP 200 via the proxy).

## 4. Post-incident (blameless)
**What went well**
- Prevention limited the blast radius: the compromised pod **could not** reach the app (NetworkPolicy), and the app pod has no
  mounted SA token / is non-root (Labs 4–5), so the same attack there would gain far less.
- Detection worked: the sensitive-file read was flagged with full pod attribution within seconds.
- Response was fast because the quarantine pattern (label + deny-all policy) was ready.

**What was missing / action items**
| # | Action | Owner | Maps to |
|---|---|---|---|
| A1 | The `default` namespace has **no** default-deny policy (only `juice-shop` does). Add one cluster-wide. | sandesh | [04](../docs/principles/04-defense-in-depth.md) |
| A2 | No Kubernetes **audit log** to answer "who created the pod?" — do Lab 12.2 (audit policy). | sandesh | [12](../docs/principles/12-assume-breach.md) |
| A3 | Falco alerts only go to pod logs; route to a SIEM/Slack (falcosidekick) so they're seen. | sandesh | [12](../docs/principles/12-assume-breach.md) |
| A4 | Enforce Pod Security `restricted` cluster-wide (only `juice-shop` enforces it), so a root busybox can't run in `default`. | sandesh | [04](../docs/principles/04-defense-in-depth.md) |

**Root cause:** simulated foothold; the real lesson is that detection + segmentation contained it, and the gaps are all *missing coverage in
other namespaces*, not failures of the controls that were in place.
