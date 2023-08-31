resource "vault_policy" "k8s_policies" {
  for_each = { for policy in local.policies : policy.name => policy }
  name     = each.key
  policy   = each.value.hcl
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "${local.project_prefix}${var.cluster_name}"
}

resource "vault_kubernetes_auth_backend_config" "default" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://${data.google_container_cluster.default.endpoint}"
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
