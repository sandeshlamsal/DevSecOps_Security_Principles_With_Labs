# Lab 10: Runtime Detection with Falco (Execution Guide)
**Lab 10** · [All labs](README.md) · [Principle 12](../principles/12-assume-breach.md) · [← Lab 9](lab-09-ai-security.md)

> **Goal:** assume prevention fails — deploy runtime detection, trigger a real alert, and read it (Lab 12.1).
> **Closes the "detect" gap** left after Labs 4–6 (prevention). **Executed:** 2026-09-26.

---

## Step 1: Is the environment capable? (check before installing)
Falco's modern eBPF probe needs kernel BTF.
```bash
docker exec secops-lab-worker uname -r                 # 6.12.76-linuxkit (Docker Desktop VM)
docker exec secops-lab-worker ls /sys/kernel/btf/vmlinux   # present -> modern eBPF viable
```

## Step 2: Install Falco (modern eBPF)
```bash
make falco-up      # helm install, driver.kind=modern_ebpf, pinned chart 9.2.0 (platform/falco/values.yaml)
kubectl -n falco get pods
```
All three node agents reach `2/2 Running`, and the logs show the probe loaded:
```
Opening 'syscall' source with modern BPF probe.
```

## Step 3: Trigger a detection
Simulate an intruder reading the password hashes inside a container:
```bash
kubectl run shell-probe --image=busybox:1.37 --command -- sleep 300
kubectl exec shell-probe -- sh -c "cat /etc/shadow >/dev/null; id"
make falco-alerts
```
Falco fired immediately, with full Kubernetes attribution:
```
Warning Sensitive file opened for reading by non-trusted program |
  file=/etc/shadow user=root process=cat parent=sh command=cat /etc/shadow
  container_name=shell-probe container_image_repository=docker.io/library/busybox
  container_image_tag=1.37 k8s_pod_name=shell-probe k8s_ns_name=default
```
Detection identifies **what** (`cat /etc/shadow`), **where** (pod `shell-probe`, namespace `default`, the busybox image), and **who** (root)
— exactly what an on-call responder needs.

## Step 4: Map to MITRE ATT&CK and write the triage
| Field | Value |
|---|---|
| Rule | Sensitive file opened for reading by non-trusted program |
| ATT&CK | **T1003.008** OS Credential Dumping: /etc/passwd and /etc/shadow |
| Triage | Identify the pod/namespace/image; is this a known job? Check who started the pod (audit log, Lab 12.2); if unexpected, isolate the pod (NetworkPolicy / delete), preserve it for forensics, rotate anything it could read |
| Runbook | Follows the [security-incident template](../templates/security-incident.md): detect → contain → eradicate → recover → postmortem |

**Prevention + detection together:** Labs 4–6 make the juice-shop pod hard to misuse (non-root, no caps, read-only proxy, NetworkPolicy);
Falco catches misuse anywhere in the cluster if prevention is bypassed. That's [defence in depth](../principles/04-defense-in-depth.md) with
both a preventive and a detective layer.

## Teardown
```bash
make falco-down     # remove Falco when done (frees ~0.5 GiB across the nodes)
```

---

## Lab 10 exit checklist
- [x] Confirmed the node kernel has BTF before choosing the modern eBPF driver
- [x] Falco installed as code (pinned chart + values.yaml + make targets)
- [x] Triggered a real detection (sensitive-file read) and read the alert with full pod attribution
- [x] Mapped the rule to MITRE ATT&CK and wrote the triage steps

**Interview takeaway:** "You get a Falco alert: shell/sensitive-file access in a production container at 2 a.m. What now?" Identify the
pod/namespace/image from the alert, decide known-vs-unexpected, contain (isolate/delete) while preserving evidence, rotate exposed secrets,
then postmortem. And know detection is the safety net for when prevention fails — you need both.

---

## Issues log
| ID | Symptom | Root cause | Lesson |
|---|---|---|---|
| L10-ISSUE-1 | `kubectl exec -it` warned "Unable to use a TTY" | Non-interactive shell in this session | Not needed — the sensitive-file rule fired without a TTY; the "terminal shell" rule specifically needs one |
| L10-ISSUE-2 | Couldn't exec a shell into juice-shop to test | It's distroless (no shell) — a security feature (Principle 05) | Use a throwaway busybox pod to generate benign test events |

---
**Lab 10** · [All labs](README.md) · [Principle 12](../principles/12-assume-breach.md) · [← Lab 9](lab-09-ai-security.md)
