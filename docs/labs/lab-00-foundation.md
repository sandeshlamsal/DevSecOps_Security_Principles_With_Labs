# Lab 0: Foundation and Security Baseline (Execution Guide)
**Lab 0** · [All labs](README.md) · [Principles](../principles/README.md) · [Next: Principle 01 →](../principles/01-cia-triad-and-risk.md)

> **Goal:** a 3-node local Kubernetes cluster running OWASP Juice Shop, reachable only from your machine, plus a written
> **security baseline**: what's exposed and what's already protected, *before* changing anything.
> **Principles practised:** know what you run, attack-surface awareness ([05](../principles/05-attack-surface-reduction.md)), evidence over opinion.
> **Time:** about 15 minutes.

This guide records **exactly what was run**, the real output, and every issue hit along the way.

---

## Environment used

| Item | Value |
|---|---|
| Date executed | 2026-09-26 |
| Machine | MacBook Pro (Intel), 12 threads, 32 GB RAM, macOS (Darwin 24.6) |
| Docker Desktop | Engine 29.4.2 (8 CPUs, ~11.7 GiB given to Docker) |
| kind | v0.31.0 |
| kubectl | v1.35.3 |
| Kubernetes (node image) | `kindest/node:v1.35.0`, pinned in [cluster.yaml](../../platform/kind/cluster.yaml) |
| App | `bkimminich/juice-shop:v20.2.0`, pinned in [juice-shop.yaml](../../apps/juice-shop/juice-shop.yaml) and the [Makefile](../../Makefile) |

---

## Step 1: Create the cluster

```bash
make cluster-up     # kind create cluster + wait for all nodes Ready
kubectl config current-context      # kind-secops-lab
kubectl get nodes
```
Took **54 s**. Output:
```
NAME                       STATUS   ROLES           AGE   VERSION
secops-lab-control-plane   Ready    control-plane   26s   v1.35.0
secops-lab-worker          Ready    <none>          15s   v1.35.0
secops-lab-worker2         Ready    <none>          15s   v1.35.0
```

## Step 2: Deploy Juice Shop

```bash
make deploy         # checks the image tag matches the Makefile pin, applies the manifest, waits for rollout
make status
```
Took **23 s**:
```
NAME                          READY   STATUS    RESTARTS   AGE   NODE
juice-shop-85d468df8b-r68fk   1/1     Running   0          23s   secops-lab-worker2
```
The manifest is deliberately **unhardened** (no securityContext, default service account). That's the "before" picture that
later labs improve, one visible diff at a time.

## Step 3: Open it, on localhost only

```bash
make open           # kubectl port-forward --address 127.0.0.1 ... 3000:3000
```
`--address 127.0.0.1` is a security control: the intentionally vulnerable app is not reachable from your Wi-Fi network.
Browse to http://localhost:3000 and use it as a normal customer: register, search, add to basket.

Smoke test:
```bash
for p in / /rest/admin/application-version /api/Products /ftp /metrics; do
  printf "%-34s %s\n" "$p" "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000$p)"; done
curl -s http://127.0.0.1:3000/rest/admin/application-version     # {"version":"20.2.0"}
```
```
/                                  200
/rest/admin/application-version    200
/api/Products                      200     (46 products, no login needed)
/ftp                               200     ← directory listing, no login needed
/metrics                           200     ← Prometheus metrics, no login needed
```

## Step 4: Security posture baseline

A security engineer's first job on any system: **find out what's there before changing it.** Each check below maps to a principle.

**4a. HTTP response headers** ([06 Secure defaults](../principles/06-secure-defaults.md))
```bash
curl -sI http://127.0.0.1:3000/ | grep -iE 'x-frame|x-content|content-security|strict-transport|access-control|feature-policy'
```
```
Access-Control-Allow-Origin: *          ← F-007
X-Content-Type-Options: nosniff         ✅
X-Frame-Options: SAMEORIGIN             ✅
Feature-Policy: payment 'self'
                                        (no Content-Security-Policy ← F-008)
```

**4b. What's publicly exposed** ([05 Attack surface](../principles/05-attack-surface-reduction.md))
```bash
curl -s http://127.0.0.1:3000/ftp | grep -oE 'href="[^"]+"' | head -5
curl -s http://127.0.0.1:3000/metrics | head -3
```
```
href="ftp/quarantine"
href="ftp/acquisitions.md"              ← internal-looking business document, public (F-005)
href="ftp/announcement_encrypted.md"
# HELP juiceshop_llm_input_tokens_total Number of total input tokens processed   ← metrics public (F-006); also reveals an LLM feature (Principle 13)
```

**4c. Pod and container security context** ([03 Least privilege](../principles/03-least-privilege.md))
```bash
kubectl -n juice-shop get pod -l app=juice-shop -o json | python3 -c "
import json,sys;p=json.load(sys.stdin)['items'][0]['spec'];c=p['containers'][0]
print('pod securityContext:',p.get('securityContext'));print('container securityContext:',c.get('securityContext'))
print('serviceAccount:',p.get('serviceAccountName'))"
kubectl -n juice-shop get pod -l app=juice-shop -o jsonpath='{.items[0].spec.containers[0].volumeMounts[*].mountPath}'
```
```
pod securityContext: {}
container securityContext: None                                ← F-002
serviceAccount: default
/var/run/secrets/kubernetes.io/serviceaccount                  ← API token mounted (F-001)
```

**4d. Which user does the image run as?** (See ISSUE-1 and ISSUE-2 for how we got here.)
```bash
docker exec secops-lab-worker2 crictl inspecti docker.io/bkimminich/juice-shop:v20.2.0 \
  | python3 -c "import json,sys;print('image user:',json.load(sys.stdin)['info']['imageSpec']['config'].get('User'))"
```
```
image user: 65532                       ✅ non-root, even with no securityContext
```

**4e. Network and admission controls** ([04 Defence in depth](../principles/04-defense-in-depth.md))
```bash
kubectl get networkpolicy -A            # No resources found            ← F-003
kubectl get ns juice-shop --show-labels # only kubernetes.io/metadata.name=juice-shop, no pod-security.* labels ← F-004
```

**Result:** 9 findings recorded in the [finding register](../../findings/README.md), plus 3 positive observations.

---

## Lab 0 exit checklist

- [x] 3-node cluster running, all nodes Ready
- [x] Juice Shop deployed with a pinned image; 1/1 Ready, 0 restarts
- [x] App reachable on `127.0.0.1` only
- [x] Security baseline taken: headers, exposure, pod security, image user, network and admission controls
- [x] 9 findings recorded with CIA impact, risk and the principle and lab that will fix each one

**Interview takeaway:** "You've just joined a team. How do you assess the security of a service you've never seen?"
You can now answer with a real method: inventory, exposure, identity and privileges, network, admission, and the evidence for each.

---

## Issues log

| ID | Step | Symptom | Root cause | Fix | Verified by |
|---|---|---|---|---|---|
| ISSUE-1 | 4d | `kubectl exec deploy/juice-shop -- id` → `exec: "id": executable file not found in $PATH` (same for `ls`) | The image is **distroless**: no shell or coreutils. This is a security *feature* (Principle 05), not a bug | Inspect the image config instead of exec-ing into it (4d). For interactive debugging later, use `kubectl debug` with an ephemeral container | Image user read from the config: `65532` |
| ISSUE-2 | 4d | `docker image inspect bkimminich/juice-shop:v20.2.0` on the Mac found nothing | kind nodes pull images into their **own containerd**, not the host's Docker image store | Ran `crictl inspecti` inside the kind node that runs the pod (`secops-lab-worker2`) | Command returned the image config |
| ISSUE-3 | 4e | A quick count `kubectl get networkpolicy -A --no-headers 2>&1 \| wc -l` returned `1`, suggesting a policy existed | The `1` was the `No resources found` message (stderr merged into the count) | Read the plain output instead of counting lines. Lesson: **check your evidence**, don't trust a number you didn't look at | `kubectl get networkpolicy -A` → `No resources found` |

---

## Teardown and rebuild

```bash
make undeploy        # remove the app, keep the cluster
make cluster-down    # delete the cluster (everything is in Git, so rebuilding takes ~2 minutes)
make cluster-up && make deploy
```

---
**Lab 0** · [All labs](README.md) · [Next: Principle 01 →](../principles/01-cia-triad-and-risk.md)
