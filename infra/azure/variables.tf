variable "prefix" {
  description = "Name prefix for every resource"
  type        = string
  default     = "secops-lab"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "budget_amount" {
  description = "Monthly budget in the subscription currency; alerts at 50/80/100% actual and 100% forecast"
  type        = number
  default     = 20
}

variable "budget_contact_emails" {
  description = "Who gets budget alerts"
  type        = list(string)
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the Kubernetes API (your public IP as x.x.x.x/32). Never 0.0.0.0/0."
  type        = list(string)
  validation {
    condition     = length(var.api_server_authorized_ip_ranges) > 0 && !contains(var.api_server_authorized_ip_ranges, "0.0.0.0/0")
    error_message = "Set at least one CIDR, and never 0.0.0.0/0 (Principle 05: minimise attack surface)."
  }
}

variable "aks_admin_group_object_ids" {
  description = "Entra ID group(s) whose members are cluster admins (no local admin account exists)"
  type        = list(string)
}

variable "kubernetes_version" {
  type    = string
  default = null # latest default version in the region
}

variable "node_vm_size" {
  type    = string
  default = "Standard_B2ms"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "enable_defender" {
  description = "Microsoft Defender for Containers + Log Analytics. Extra cost: turn on for the Phase 2 detection weeks, then off."
  type        = bool
  default     = false
}

variable "enable_pod_security_policy" {
  description = "Assign the built-in Azure Policy initiative for restricted pod security on this cluster"
  type        = bool
  default     = true
}
