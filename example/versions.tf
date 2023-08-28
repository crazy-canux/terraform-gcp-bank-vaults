terraform {
  backend "gcs" {
    bucket = "arm-phoenix-flav-c-tst-iac"
    prefix = "terraform/eu-west-4/vsw.tfstate"
  }

  required_version = ">= 1.2.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.66.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.3.0"
    }
  }
}

