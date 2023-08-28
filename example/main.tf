locals {
  project         = data.terraform_remote_state.vpc.outputs.project
  region          = data.terraform_remote_state.vpc.outputs.region
  labels          = data.terraform_remote_state.vpc.outputs.labels
  zones           = data.terraform_remote_state.vpc.outputs.zones
  cluster_name    = data.terraform_remote_state.gke.outputs.name
  vault_url       = "https://vault.arm.com/"
  vault_namespace = "iac-phoenix/test"
}

###############################
# Data
##############################
data "google_client_config" "this" {}

data "google_container_cluster" "this" {
  name     = local.cluster_name
  location = local.region
}

data "terraform_remote_state" "gke" {
  backend = "gcs"
  config = {
    bucket = "arm-phoenix-flav-c-tst-iac"
    prefix = "terraform/eu-west-4/gke.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "gcs"
  config = {
    bucket = "arm-phoenix-flav-c-tst-iac"
    prefix = "terraform/eu-west-4/vpc.tfstate"
  }
}
# enable for TFE
# data "vault_generic_secret" "gcp_role_config" {
#   path = "${var.armtfe_vault_gcp_engine_path}/${var.armtfe_vault_gcp_engine_role}"
# }

# data "vault_generic_secret" "gcp_access_token" {
#   path = "${var.armtfe_vault_gcp_engine_path}/${var.armtfe_vault_gcp_engine_role}/token"
# }

##############################
# Provider
##############################
provider "vault" {
  address          = local.vault_url
  namespace        = local.vault_namespace
  skip_child_token = true
  # enable for TFE
  # auth_login {
  #   path      = "auth/${var.armtfe_vault_approle_auth_backend}/login"
  #   namespace = var.armtfe_vault_approle_auth_namespace
  #   parameters = {
  #     role_id   = var.armtfe_vault_approle_auth_role_id
  #     secret_id = var.armtfe_vault_approle_auth_secret_id
  #   }
  # }
}

provider "google" {
  project = local.project
  region  = local.region
  # enable for TFE
  # project      = data.vault_generic_secret.gcp_role_config.data["service_account_project"]
  # access_token = data.vault_generic_secret.gcp_access_token.data["token"]
  # region       = var.gcp_region
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.this.endpoint}"
    cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.this.access_token
  }
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.this.access_token
}

##############################
# Module/Resources
##############################
module "secrets_webhook" {
  source          = "../../terraform-gcp-bank-vaults"
  vault_url       = local.vault_url
  vault_namespace = local.vault_namespace
  cluster_name    = local.cluster_name
  extra_set_values = [{
    name  = "nodeSelector.kubernetes\\.io/arch"
    value = "arm64"
    type  = "string"
  }]

  vault_policies = [
    {
      name = "${local.vault_namespace}/it/pki/domain-owner"
      hcl  = <<-EOT
        path "it/pki/*" {
          capabilities = ["read", "list"]
        }
        path "it/pki/issue/domain-owner" {
          capabilities = ["create","update"]
        }
        path "it/pki/issuer/+/issue/domain-owner" {
          capabilities = ["create","update"]
        }
        path "it/pki/sign/domain-owner" {
          capabilities = ["create","update"]
        }
        path "it/pki/issuer/+/sign/domain-owner" {
          capabilities = ["create","update"]
        }
        EOT
    },
    {
      name = "${local.vault_namespace}/demo"
      hcl  = <<-EOT
        path "demo/data/*" {
            capabilities = ["read", "list"]
        }
        EOT
    }
  ]

  extra_sa_mappings = [{
    name = "${replace(local.vault_namespace, "/", "-")}_cert-manager_cluster-issuer"
    identities = [
      { ns = "cert-manager", sa = "cert-manager-deployer-issuer" }
    ]
    policies = ["${local.vault_namespace}/it/pki/domain-owner"]
    ttl      = 7200
    },
    {
      name = "${replace(local.vault_namespace, "/", "-")}_demo"
      identities = [
        { ns = "canux", sa = "vault-sa" },
      ]
      policies = ["${local.vault_namespace}/demo"]
      ttl      = 3600
  }]
}