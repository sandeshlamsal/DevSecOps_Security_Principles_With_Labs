output "resource_group" { value = azurerm_resource_group.lab.name }
output "aks_name" { value = azurerm_kubernetes_cluster.lab.name }
output "oidc_issuer_url" { value = azurerm_kubernetes_cluster.lab.oidc_issuer_url }
output "key_vault_name" { value = azurerm_key_vault.lab.name }
output "juice_shop_client_id" {
  description = "Put this in the juice-shop ServiceAccount annotation azure.workload.identity/client-id"
  value       = azurerm_user_assigned_identity.juice_shop.client_id
}
