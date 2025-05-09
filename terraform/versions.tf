terraform {
  required_version = ">= 1.11" # Specify a recent Terraform version

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.34" # Use a recent version of the Google provider
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
