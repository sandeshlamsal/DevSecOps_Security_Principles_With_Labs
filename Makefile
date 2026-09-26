CLUSTER   := secops-lab
NAMESPACE := juice-shop
# Pinned so the lab is reproducible. Bump deliberately and note it in docs/labs/.
JUICE_SHOP_VERSION := v20.2.0

.PHONY: help cluster-up cluster-down deploy undeploy status open ci security-scan az-plan az-up az-creds az-down falco-up falco-down

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk -F':.*?## ' '{printf "  %-14s %s\n", $$1, $$2}'

cluster-up: ## Create the local kind cluster
	kind create cluster --config platform/kind/cluster.yaml
	kubectl wait --for=condition=Ready nodes --all --timeout=180s

cluster-down: ## Delete the local kind cluster
	kind delete cluster --name $(CLUSTER)

deploy: ## Deploy OWASP Juice Shop (intentionally vulnerable; localhost only)
	@grep -q "juice-shop:$(JUICE_SHOP_VERSION)" apps/juice-shop/juice-shop.yaml || { echo "image tag drift: manifest != Makefile $(JUICE_SHOP_VERSION)"; exit 1; }
	kubectl apply -f apps/juice-shop/juice-shop.yaml
	kubectl apply -f platform/network/juice-shop-netpol.yaml
	kubectl -n $(NAMESPACE) rollout status deploy/juice-shop --timeout=300s

undeploy: ## Remove Juice Shop
	kubectl delete namespace $(NAMESPACE) --ignore-not-found

status: ## Show pod status
	kubectl get pods -n $(NAMESPACE) -o wide

open: ## Port-forward Juice Shop VIA THE HARDENED PROXY to http://localhost:3000 (127.0.0.1 only)
	@echo "Juice Shop (via proxy): http://localhost:3000   (score board: http://localhost:3000/#/score-board)"
	@echo "The proxy blocks /ftp, /encryptionkeys, /support/logs, /metrics, /infrastructure (plan B1)."
	kubectl port-forward --address 127.0.0.1 -n $(NAMESPACE) svc/juice-shop-proxy 3000:8080

ci: ## Run all CI checks locally (same script as GitHub Actions)
	scripts/ci.sh

security-scan: ## Run the security gates locally (same script as the security workflow)
	scripts/security-scan.sh

FALCO_VERSION := 9.2.0
falco-up: ## Install Falco runtime detection (modern eBPF) into the falco namespace
	helm repo add falcosecurity https://falcosecurity.github.io/charts >/dev/null 2>&1 || true
	helm repo update falcosecurity >/dev/null
	helm upgrade --install falco falcosecurity/falco --version $(FALCO_VERSION) \
	  -n falco --create-namespace -f platform/falco/values.yaml --wait --timeout 5m

falco-down: ## Remove Falco
	helm uninstall falco -n falco || true
	kubectl delete ns falco --ignore-not-found

falco-alerts: ## Tail recent Falco alerts across all nodes
	kubectl -n falco logs -l app.kubernetes.io/name=falco -c falco --since=5m | grep -iE 'Warning|Notice|Critical|Error' || echo 'no recent alerts'

# ---- Phase 2: Azure (costs money while up: ~$0.30-0.50/hr; ALWAYS `make az-down` after a session) ----
AZ_DIR := infra/azure
az-plan: ## Terraform plan for the secure AKS lab (free; needs infra/azure/terraform.tfvars)
	cd $(AZ_DIR) && terraform init -input=false >/dev/null && terraform plan -input=false -out=plan.tfplan

az-up: az-plan ## Create the Azure lab (budget alert first)
	cd $(AZ_DIR) && terraform apply -input=false plan.tfplan

az-creds: ## Get Entra ID kubeconfig for the AKS lab (no local admin account exists)
	az aks get-credentials -g secops-lab-rg -n secops-lab-aks --context secops-lab-aks --overwrite-existing
	kubelogin convert-kubeconfig -l azurecli

az-down: ## DESTROY everything in the Azure lab resource group
	cd $(AZ_DIR) && terraform destroy -input=false -auto-approve
	-kubectl config delete-context secops-lab-aks
