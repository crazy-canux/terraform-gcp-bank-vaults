terraform {
  required_version = ">= 1.1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.66.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 1.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.3.0"
    }
  }
}
