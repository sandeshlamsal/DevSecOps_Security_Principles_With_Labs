# Cloud Security Labs: Azure (Roadmap Phase 2)

These labs take the principles into a real cloud. Everything is created from [infra/azure/](../../infra/azure/) (Terraform), which is
**secure by default**: each setting is commented with the principle or finding it addresses. Background on the cloud layer:
[stack guide §3](../architecture/README.md#3-layer-1-cloud). Schedule: [roadmap Phase 2](../career/ROADMAP.md#phase-2-cloud-security-on-azure-weeks-716).

> 💰 **Cost rules** (same as the SRE lab's AKS phase)
> 1. `make az-plan` is free. Read the plan before every apply.
> 2. `make az-up` creates ~$0.30–0.50/hour of resources (2× B2ms nodes). `enable_defender = true` adds Defender + Log Analytics cost (capped at 1 GB/day).
> 3. **Always run `make az-down` at the end of a session.** The budget alert (50/80/100%) is created first as a safety net, not a plan.

## What the Terraform builds

| Resource | Security settings | Principle |
|---|---|---|
| Budget alert | 50/80/100% actual + 100% forecast | Guardrail |
| AKS cluster | Entra ID + Azure RBAC, **local accounts disabled**, API server limited to your IP, workload identity + OIDC issuer, Azure Policy add-on, Key Vault CSI with rotation, Cilium NetworkPolicy, auto patch + node image upgrades, image cleaner | 03, 04, 05, 08, 09, 10 |
| Key Vault | RBAC mode, purge protection, soft delete, network default **Deny** except your IP | 09 |
| Workload identity for Juice Shop | Federated to exactly one ServiceAccount; only **Key Vault Secrets User** | 03, 08 |
| Azure Policy assignment | Built-in *restricted* pod security initiative, in **Audit** (lab AZ-8 switches to Deny) | 04, 11 |
| Defender for Containers (optional) | Runtime threat detection + Log Analytics with a daily cap | 12 |

## First-time setup

```bash
brew install azure-cli Azure/kubelogin/kubelogin   # kubelogin: Entra ID auth for kubectl (local accounts are disabled)
az login
az account show --query '{sub:name, id:id}' -o table            # confirm the subscription
cp infra/azure/terraform.tfvars.example infra/azure/terraform.tfvars   # git-ignored; fill in your IP, email, admin group
make az-plan                                                       # free: read what will be created
```

## Labs

Each lab: **do it, capture the evidence, write the finding or runbook**. Execution guides go in [docs/labs/](../labs/README.md) as `lab-az-N-*.md`.

### AZ-1: Identity inventory (no resources created) ⏳
1. `az role assignment list --all --include-inherited -o table` for your subscription.
2. List every Owner and Contributor, and every service principal with rights. For each: is it still needed? Could it be narrower?
3. Check MFA / Conditional Access coverage for admins in the Entra admin centre.
**Evidence:** a table of identities, roles and scopes, with a recommendation per row.

### AZ-2: Least-privilege custom role ⏳
1. Write a custom role that can only start/stop the lab's AKS cluster and read its resource group.
2. Assign it to a test user or service principal at **resource-group scope**. Prove with `az` that it can stop AKS but can't read Key Vault secrets.
3. Explain Azure RBAC evaluation: scope inheritance, additive permissions, deny assignments, `NotActions`.

### AZ-3: Secure foundation and a restricted API server ⏳
1. `make az-up`. Then `make az-creds` (Entra ID login; there is no local admin kubeconfig).
2. From your IP: `kubectl get nodes` works. Change `api_server_authorized_ip_ranges` to another IP and `make az-plan az-up`: the same command now times out.
3. Try `az aks get-credentials --admin` and record the error (local accounts are disabled).

### AZ-4: Workload identity: a secret with no stored credential ⏳
1. Store a test secret in Key Vault. Deploy Juice Shop's ServiceAccount with the annotation `azure.workload.identity/client-id: <terraform output juice_shop_client_id>`.
2. Mount the secret with the Key Vault CSI driver. Show the pod reads it, and that **no** client secret exists anywhere.
3. Change the ServiceAccount name: access fails (the federated credential is bound to one subject).

### AZ-5: Keys and encryption ⏳
Rotate the Key Vault secret and watch the CSI driver pick up the new value. Compare platform-managed vs customer-managed keys, and
turn on host encryption for nodes (a subscription feature flag). Write a rotation runbook.

### AZ-6: Logging and "who did what" ⏳
Delete a resource on purpose, then find the actor, time and operation in the Activity Log with KQL
(`az monitor activity-log list` or Log Analytics). Save the queries in `docs/cloud/kql/`.

### AZ-7: Detection with Defender for Cloud ⏳
Set `enable_defender = true` for this week only. Review Defender CSPM recommendations and Defender for Containers alerts, trigger a
benign test alert, and triage five items into the [finding register](../../findings/README.md). Then turn it off again.

### AZ-8: Guardrails with Azure Policy + Checkov ⏳
1. Check compliance of the pod-security assignment (Audit mode). Deploy a privileged test pod: it's **reported**.
2. Switch the effect to `Deny`, re-apply: the same pod is **rejected** at admission.
3. `checkov -d infra/azure` and fix or document every failure. The result becomes capstone **M1**.

## Lab status

| Lab | Status |
|---|---|
| Terraform foundation | ✅ written, `terraform validate` passes (2026-09-26); not yet applied |
| AZ-1 … AZ-8 | ⏳ |
