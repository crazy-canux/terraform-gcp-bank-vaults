variable "location" {
  description = "gke region"
  type        = string
  default     = "europe-west4"
}

variable "vault_url" {
  description = "Vault URL"
  type        = string
}

variable "vault_namespace" {
  description = "Namespace being used for the Vault provider passed to this module (Vault Enterprise only)"
  type        = string
  default     = ""
}

variable "chart_repo_url" {
  description = "URL to repository containing the vault-secrets-webhook helm chart"
  type        = string
  default     = "oci://ghcr.io/bank-vaults/helm-charts"
}

variable "helm_deployment_name" {
  description = "Name for helm deployment"
  type        = string
  default     = "vault-secrets-webhook"
}

variable "helm_chart_version" {
  description = "Version of the vault-secrets-webhook chart"
  type        = string
  default     = "1.20.0"
}

variable "namespace" {
  description = "Name for vault-secrets-webhook namespace"
  type        = string
  default     = "vault-secrets-webhook"
}

variable "service_account" {
  description = "Name for vault-secrets-webhook namespace"
  type        = string
  default     = "vault-webhook-admin"
}

variable "webhook_vault_base_policy" {
  description = "Default policy for the webhook's service acccount in vault"
  type        = string
  default     = ""
}

variable "webhook_vault_extra_policies" {
  description = "Any additional policies for the webhook's service acccount in vault"
  type        = list(string)
  default     = []
}

variable "helm_values" {
  description = "Values for vault-secrets-webhook Helm chart in raw YAML. If none specified, module will add its own set of default values"
  type        = list(string)
  default     = []
}

variable "extra_set_values" {
  description = "Specific values to override in the vault-secrets-webhook Helm chart (overrides corresponding values in the helm-value.yaml file within the module)"
  type = list(object({
    name  = string
    value = any
    type  = string
    })
  )
  default = []
}

variable "project" {
  description = "Name of top level project in Vault OSS - leave this undefined for Vault Enterprise"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "vault_policies" {
  description = "Additional policies to be created in vault"
  type = list(object({
    name = string
    hcl  = string
    })
  )
  default = []
}

variable "extra_sa_mappings" {
  description = "Additional Kubernetes service account mappings to policies in Vault"
  type = list(object({
    name = string
    identities = list(object({
      sa = string
      ns = string
    }))
    policies = list(string)
    ttl      = number
    })
  )
  default = []
}
