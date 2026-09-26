CLUSTER   := secops-lab
NAMESPACE := juice-shop
# Pinned so the lab is reproducible. Bump deliberately and note it in docs/labs/.
JUICE_SHOP_VERSION := v20.2.0

.PHONY: help cluster-up cluster-down deploy undeploy status open ci

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
	kubectl -n $(NAMESPACE) rollout status deploy/juice-shop --timeout=300s

undeploy: ## Remove Juice Shop
	kubectl delete namespace $(NAMESPACE) --ignore-not-found

status: ## Show pod status
	kubectl get pods -n $(NAMESPACE) -o wide

open: ## Port-forward Juice Shop to http://localhost:3000 (bound to 127.0.0.1 only)
	@echo "Juice Shop: http://localhost:3000   (score board: http://localhost:3000/#/score-board)"
	kubectl port-forward --address 127.0.0.1 -n $(NAMESPACE) svc/juice-shop 3000:3000

ci: ## Run all CI checks locally (same script as GitHub Actions)
	scripts/ci.sh
