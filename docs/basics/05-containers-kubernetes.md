# Baby Step 5: Containers and Kubernetes

## The concepts
- **Image:** a packaged filesystem + start command (e.g. `bkimminich/juice-shop:v20.2.0`). It contains your app **and** every
  library and OS package, so every vulnerability in them too.
- **Container:** a running image. It's an isolated *process*, not a virtual machine: it shares the host's kernel.
- **Pod:** Kubernetes' smallest unit, one or more containers together.
- **Namespace:** a folder-like boundary for grouping resources and applying policies (our app lives in `juice-shop`).
- **Service account:** the identity a pod uses to talk to the Kubernetes API. Pods get a token by default.
- **RBAC:** Roles list allowed actions (`get pods`, `list secrets`); RoleBindings give them to users or service accounts.
- **Admission control:** checks that run when something is created, and can reject it (Pod Security, Kyverno).

## Try it (lab running)
```bash
kubectl get ns                                         # namespaces
kubectl -n juice-shop get deploy,pod,svc               # what runs the app
kubectl -n juice-shop get pod -l app=juice-shop -o yaml | grep -A3 -E 'securityContext|serviceAccountName'
kubectl auth can-i --list -n juice-shop                # what can YOU do? (as cluster admin: everything)
kubectl auth can-i list secrets -n juice-shop --as=system:serviceaccount:juice-shop:default
```

## Check yourself
1. Why is "containers are isolated" only partly true?
2. What's the difference between a Role and a RoleBinding?
3. Why does it matter that pods get a service-account token by default?
