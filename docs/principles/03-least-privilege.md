# 03: Least Privilege

> "Every program and every user should operate using the least set of privileges necessary to complete the job." (Saltzer & Schroeder, 1975)

## In plain words
Give every person, service, container and token **only** the access it needs, **only** for as long as it needs it.
When something is compromised (and eventually something will be), least privilege limits the **blast radius**.

Where it applies:

| Layer | Too much privilege looks like | Least privilege looks like |
|---|---|---|
| Humans | Everyone is admin | Role-based access, just-in-time elevation |
| App → database | App connects as DB owner | Separate read/write users, no DDL rights |
| Container | Runs as root, all Linux capabilities | Non-root, `drop: [ALL]`, no privilege escalation |
| Kubernetes | Default service-account token mounted everywhere | No token unless needed; narrow RBAC Roles |
| Cloud | `*:*` IAM policies | Scoped policies per workload |

## Why it matters
**Capital One (2019):** an attacker used a server-side request forgery (SSRF) flaw to obtain credentials from a cloud
instance's metadata service. Those credentials belonged to a role that could list and read far more storage buckets than
the workload needed, which turned one bug into a breach of about 100 million records.

## In our lab
- ✅ Good: the image runs as a non-root user (UID `65532`) and is distroless (there's no shell to abuse).
- ❌ **F-001:** the pod uses the `default` service account, and its API token is mounted at `/var/run/secrets/kubernetes.io/serviceaccount`.
- ❌ **F-002:** no `securityContext`: privilege escalation isn't blocked, and Linux capabilities aren't dropped.

## Hands-on labs

### Lab 3.1: Remove the service-account token ✅ ([execution guide](../labs/lab-04-least-privilege.md))
1. Confirm the finding: `kubectl -n juice-shop get pod -l app=juice-shop -o jsonpath='{.items[0].spec.containers[0].volumeMounts}'`
2. Create a dedicated ServiceAccount for Juice Shop, and set `automountServiceAccountToken: false` in the pod spec.
3. Redeploy, then re-run step 1 and confirm the token mount is gone. Update F-001 to *Fixed* with the evidence.

### Lab 3.2: Harden the container securityContext ✅ ([execution guide](../labs/lab-04-least-privilege.md))
1. Add `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `capabilities: {drop: [ALL]}`, `readOnlyRootFilesystem: true`,
   and `seccompProfile: {type: RuntimeDefault}`.
2. Redeploy. If the app fails (it may need to write to a directory), find out **which** path it writes to and mount an
   `emptyDir` there only. That debugging loop is exactly the day-to-day work of a DevSecOps engineer.
3. Record each issue you hit in the lab guide's issues log.

### Lab 3.3: RBAC review ✅ ([execution guide](../labs/lab-04-least-privilege.md))
1. `kubectl auth can-i --list --as=system:serviceaccount:juice-shop:default -n juice-shop`
2. Explain each permission in the output. Then create a Role and RoleBinding for a "juice-shop-readonly" human user that
   can only `get`/`list` pods and logs in that namespace, and prove it with `kubectl auth can-i`.

## Best-practice checklist
- [ ] Workloads run as non-root, with all capabilities dropped and no privilege escalation
- [ ] Service-account tokens are mounted only for workloads that call the Kubernetes API
- [ ] RBAC uses namespaced Roles; ClusterRole bindings are rare and reviewed
- [ ] Humans get time-limited elevated access, and it's logged
- [ ] Access is reviewed regularly, and unused permissions are removed

## Interview questions
1. What is least privilege, and how would you apply it to a Kubernetes workload?
2. Why is running as root inside a container risky if the container is "isolated"?
3. What is the blast radius, and how do you reduce it?
4. How would you find over-privileged IAM roles or RBAC bindings in a large environment?
5. Walk through the Capital One breach. Which controls would have limited it?
