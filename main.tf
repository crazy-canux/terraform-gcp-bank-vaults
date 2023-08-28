
locals {
  project_prefix  = (var.project != null) ? "${var.project}/" : ""
  vault_role_name = "${var.cluster_name}_${var.namespace}_${var.service_account}"
  # TODO: Should be removed now that the admin role was removed in v0.3.0
  policies = concat(var.vault_policies, [{
    name = "${local.project_prefix}${local.vault_role_name}"
    hcl  = length(var.webhook_vault_base_policy) > 0 ? var.webhook_vault_base_policy : <<-EOT
    path "${local.project_prefix}*" {
      capabilities = ["read", "list"]
    }
    EOT
  }])
  token_review_subjects = flatten(var.extra_sa_mappings[*].identities)
}

# Data resources to retrieve data for providers
data "google_container_cluster" "default" {
  name     = var.cluster_name
  location = var.location
}

# Create namespace
resource "kubernetes_namespace" "webhook_namespace" {
  metadata {
    name = var.namespace
  }
}

# Deploy helm chart
resource "helm_release" "vault_secrets_webhook" {
  name       = var.helm_deployment_name
  repository = var.chart_repo_url
  chart      = "vault-secrets-webhook"
  version    = var.helm_chart_version
  namespace  = var.namespace
  values     = length(var.helm_values) > 0 ? var.helm_values : ["${file("${path.module}/helm-values.yaml")}"]
  set {
    name  = "env.VAULT_ADDR"
    value = var.vault_url
  }

  set {
    name  = "env.VAULT_NAMESPACE"
    value = var.vault_namespace
  }

  set {
    name  = "env.VAULT_PATH"
    value = "${local.project_prefix}${var.cluster_name}"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account
  }

  dynamic "set" {
    for_each = var.extra_set_values
    content {
      name  = set.value.name
      value = set.value.value
      type  = set.value.type
    }
  }

  depends_on = [
    kubernetes_namespace.webhook_namespace
  ]
}

resource "kubernetes_cluster_role_binding_v1" "vault_auth_delegator" {
  metadata {
    name = "vault-auth:delegators"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  dynamic "subject" {
    for_each = local.token_review_subjects

    content {
      kind      = "ServiceAccount"
      name      = subject.value.sa
      namespace = subject.value.ns
    }
  }
}
