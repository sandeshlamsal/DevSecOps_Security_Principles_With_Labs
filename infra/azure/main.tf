# Secure-by-default AKS lab for Phase 2 (cloud security) and the capstone.
# Each security setting names the principle (docs/principles/NN) or audit finding it addresses.

data "azurerm_client_config" "current" {}

locals {
  tags = { project = "secops-lab", owner = "sandesh", managed_by = "terraform" }
}

resource "azurerm_resource_group" "lab" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = local.tags
}

# GUARDRAIL FIRST: budget alerts before anything that costs money.
resource "azurerm_consumption_budget_resource_group" "lab" {
  name              = "${var.prefix}-budget"
  resource_group_id = azurerm_resource_group.lab.id
  amount            = var.budget_amount
  time_grain        = "Monthly"
  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }
  dynamic "notification" {
    for_each = [50, 80, 100]
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThanOrEqualTo"
      threshold_type = "Actual"
      contact_emails = var.budget_contact_emails
    }
  }
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = var.budget_contact_emails
  }
  lifecycle { ignore_changes = [time_period] }
}

# Only created when Defender is on (Log Analytics ingestion costs money).
resource "azurerm_log_analytics_workspace" "lab" {
  count               = var.enable_defender ? 1 : 0
  name                = "${var.prefix}-law"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1 # hard cap on ingestion cost
  tags                = local.tags
}

resource "azurerm_kubernetes_cluster" "lab" {
  # Time-limited exceptions: each one is listed with its reason and expiry in SECURITY-EXCEPTIONS.md (CI fails when one expires).
  #checkov:skip=CKV_AZURE_115:EXC-001 private cluster needs VPN/bastion; API restricted by authorized IP ranges instead
  #checkov:skip=CKV_AZURE_117:EXC-002 customer-managed disk encryption set is lab AZ-5
  #checkov:skip=CKV_AZURE_227:EXC-002 host encryption needs a subscription feature flag; lab AZ-5
  #checkov:skip=CKV_AZURE_4:EXC-003 Azure Monitor logging has ingestion cost; enabled with Defender in labs AZ-6/AZ-7
  #checkov:skip=CKV_AZURE_170:EXC-004 paid SLA tier is availability, not security; cost trade-off for a lab
  #checkov:skip=CKV_AZURE_232:EXC-004 separate system and user node pools double node cost for a lab
  #checkov:skip=CKV_AZURE_226:EXC-004 ephemeral OS disks need a VM size with enough cache; B2ms is chosen for cost
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  dns_prefix          = var.prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  tags                = local.tags

  # 08 Identity: Entra ID login + Azure RBAC for Kubernetes; no static admin kubeconfig.
  local_account_disabled = true
  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled     = true
    admin_group_object_ids = var.aks_admin_group_object_ids
  }

  # 03 Least privilege: pods get their own federated identities (workload identity), never node credentials.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # 05 Attack surface: the API server only answers your IPs.
  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  # 04 Defence in depth / 11 Security as code: Azure Policy add-on (Gatekeeper-based) for cluster guardrails.
  azure_policy_enabled = true

  # 09 Secrets: Key Vault CSI driver with rotation; secrets are mounted, never baked into images or manifests.
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # 10 Supply chain / patching: automatic patch upgrades and node image updates; remove unused images.
  automatic_upgrade_channel    = "patch"
  node_os_upgrade_channel      = "NodeImage"
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_vm_size
    node_count                  = var.node_count
    os_disk_size_gb             = 30
    os_disk_type                = "Managed"
    max_pods                    = 110
    host_encryption_enabled     = false # needs the EncryptionAtHost feature registered on the subscription; lab AZ-5 turns it on
    temporary_name_for_rotation = "systemtmp"
    upgrade_settings { max_surge = "1" }
  }

  identity { type = "SystemAssigned" }

  # 04 Defence in depth: Cilium dataplane enforces NetworkPolicy.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    load_balancer_sku   = "standard"
  }

  # 12 Assume breach: Defender for Containers (runtime threat detection), only when enabled.
  dynamic "microsoft_defender" {
    for_each = var.enable_defender ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.lab[0].id
    }
  }
}

# 09 Secrets: Key Vault in RBAC mode with purge protection. Public access is limited to your IPs.
resource "azurerm_key_vault" "lab" {
  #checkov:skip=CKV2_AZURE_32:EXC-001 private endpoint needs a private network path (VPN/bastion); network ACL default-deny + IP allow-list instead
  name                          = substr(replace("${var.prefix}-kv-${substr(data.azurerm_client_config.current.subscription_id, 0, 6)}", "-", ""), 0, 24)
  location                      = azurerm_resource_group.lab.location
  resource_group_name           = azurerm_resource_group.lab.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = true # the lab has no private network path yet; restricted by network_acls below
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.api_server_authorized_ip_ranges
  }
  tags = local.tags
}

# You (the operator) may manage secrets. Nobody else gets anything by default.
resource "azurerm_role_assignment" "kv_operator" {
  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# 03 + 08: a workload identity for Juice Shop that can READ secrets and nothing else (lab AZ-4).
resource "azurerm_user_assigned_identity" "juice_shop" {
  name                = "${var.prefix}-juice-shop-id"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "juice_shop" {
  name                = "juice-shop-sa"
  resource_group_name = azurerm_resource_group.lab.name
  parent_id           = azurerm_user_assigned_identity.juice_shop.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.lab.oidc_issuer_url
  subject             = "system:serviceaccount:juice-shop:juice-shop" # only this ServiceAccount may use the identity
}

resource "azurerm_role_assignment" "juice_shop_kv_read" {
  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.juice_shop.principal_id
}

# 04 + 11: built-in Azure Policy initiative enforcing restricted pod security on this cluster (lab AZ-8).
data "azurerm_policy_set_definition" "pod_security_restricted" {
  count        = var.enable_pod_security_policy ? 1 : 0
  display_name = "Kubernetes cluster pod security restricted standards for Linux-based workloads"
}

resource "azurerm_resource_policy_assignment" "pod_security_restricted" {
  count                = var.enable_pod_security_policy ? 1 : 0
  name                 = "${var.prefix}-pss-restricted"
  resource_id          = azurerm_kubernetes_cluster.lab.id
  policy_definition_id = data.azurerm_policy_set_definition.pod_security_restricted[0].id
  parameters = jsonencode({
    effect             = { value = "Audit" } # audit first, then switch to Deny in lab AZ-8
    excludedNamespaces = { value = ["kube-system", "gatekeeper-system", "azure-arc", "kube-public"] }
  })
}
