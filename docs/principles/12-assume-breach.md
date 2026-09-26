# 12: Assume Breach: Detect, Respond, Recover

> "Prevention eventually fails. Detection and response decide how bad it gets."

## In plain words
Design as if an attacker is already inside. Then make sure you would **notice**, **contain** and **recover**.

- **Logging:** security-relevant events (logins, failures, permission changes, admin actions, Kubernetes API audit events) are
  recorded centrally, with the time, the actor and the action, and protected from tampering.
- **Detection:** rules that turn logs and runtime behaviour into alerts. Examples: a shell spawned in a container, a read of a
  sensitive file, a new admin user.
- **Response:** the NIST incident-response lifecycle: **Prepare → Detect & analyse → Contain, eradicate & recover → Post-incident
  activity**. Preserve evidence *before* you destroy it.
- **MITRE ATT&CK** is the shared vocabulary for attacker techniques, and is used to measure what your detections cover.

## Why it matters
**Target (2013):** the security monitoring tools reportedly raised alerts about the malware, but they weren't acted on. The
detection existed; the response process didn't. Industry reports have for years put the average time to identify a breach
at many months.

## In our lab
There is no runtime detection and no central security logging yet. Kubernetes audit logging is off by default in kind.

## Hands-on labs

### Lab 12.1: Runtime detection with Falco ⏳
1. Install Falco with Helm into the lab cluster.
2. Trigger a benign test event that its default rules detect. For example, start a debug container next to Juice Shop with
   `kubectl debug` and run a shell in it.
3. Find the alert in Falco's output. Map the rule to its MITRE ATT&CK technique, and write the triage steps for it.

### Lab 12.2: Kubernetes audit logging ⏳
1. Recreate the kind cluster with an API-server audit policy (a kind config patch) that logs Secret access and `exec` requests.
2. Read a Secret and run `kubectl exec`, then find both events in the audit log and identify who did what, and when.

### Lab 12.3: Security incident game day ⏳
A partner writes a scenario (for example: "a leaked token is used to read Secrets"). You respond using the
[security-incident template](../templates/security-incident.md): detect, scope, contain, eradicate, recover, and hold a blameless
postmortem with action items that become new controls in principles 03–11.

## Best-practice checklist
- [ ] Central, tamper-resistant logs for auth, admin actions and cloud/Kubernetes audit events
- [ ] Detections are tested (you can trigger each one on purpose) and mapped to ATT&CK
- [ ] Every alert has a runbook and an owner; noisy rules are tuned, not ignored
- [ ] Incident response plan, contact list and evidence-handling steps exist *before* an incident
- [ ] Backups are tested with real restores; recovery time is measured

## Interview questions
1. Walk me through the NIST incident-response lifecycle with a real example.
2. You get an alert: "shell spawned in a production container". What do you do in the first 15 minutes?
3. What's the difference between containment and eradication? Why does the order matter?
4. What is MITRE ATT&CK, and how would you use it to find gaps in detection?
5. What should be logged for security, and what should never be logged?
