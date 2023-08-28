
# terraform bank vaults

provision vault-secrets-webhook to GKE.

## Synopsis

provider

    provider "google" {
      project = local.project
      region  = local.region
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

    provider "vault" {
      address   = local.vault_url
      namespace = local.vault_namespace
      skip_child_token = true
    }

module

    module "secrets_webhook" {
      source          = "../../terraform-gcp-bank-vaults"
      vault_url       = local.vault_url
      vault_namespace = local.vault_namespace
      cluster_name    = local.cluster_name
      vault_policies = []
      extra_sa_mappings = []
    }
