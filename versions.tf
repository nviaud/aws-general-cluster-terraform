terraform {
  required_version = ">= 1.5"

  # UNCOMMENT AFTER RUNNING backend-setup and migrating state
  # backend "s3" {
  #   bucket         = "<project-name>-<environment>-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "<aws-region>"
  #   dynamodb_table = "<project-name>-<environment>-terraform-locks"
  #   encrypt        = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}
