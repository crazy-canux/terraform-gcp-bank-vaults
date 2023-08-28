resource "vault_policy" "k8s_policies" {
  for_each = { for policy in local.policies : policy.name => policy }
  name     = each.key
  policy   = each.value.hcl
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "${local.project_prefix}${var.cluster_name}"
}

# https://developer.hashicorp.com/vault/docs/auth/kubernetes#use-the-vault-client-s-jwt-as-the-reviewer-jwt
# Use the Vault client's JWT as the reviewer JWT
#
# When configuring Kubernetes auth, you can omit the
# token_reviewer_jwt, and Vault will use the Vault
# client's JWT as its own auth token when communicating
# with the Kubernetes TokenReview API. If Vault is
# running in Kubernetes, you also need to set disable_local_ca_jwt=true.

resource "vault_kubernetes_auth_backend_config" "default" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = data.google_container_cluster.default.endpoint
  kubernetes_ca_cert     = base64decode(data.google_container_cluster.default.master_auth[0].cluster_ca_certificate)
  disable_iss_validation = true
  disable_local_ca_jwt = true
}

resource "vault_kubernetes_auth_backend_role" "webhook_roles" {
  for_each                         = { for mapping in var.extra_sa_mappings : mapping.name => mapping }
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = each.value.name
  bound_service_account_names      = [for ident in each.value.identities : ident.sa]
  bound_service_account_namespaces = [for ident in each.value.identities : ident.ns]
  token_ttl                        = each.value.ttl
  token_policies                   = each.value.policies
}
