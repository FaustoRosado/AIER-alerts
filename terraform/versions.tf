# AI/ER Capstone Project - Terraform Version Management
# Sprint 2: Provider and Version Control

terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"

      # Security and compliance considerations
      configuration_aliases = [aws.replica]
    }

    # Future providers for enhanced functionality
    # random = {
    #   source  = "hashicorp/random"
    #   version = "~> 3.1"
    # }

    # tls = {
    #   source  = "hashicorp/tls"
    #   version = "~> 4.0"
    # }
  }
}

# Provider configurations for different environments
locals {
  provider_configs = {
    dev = {
      region = "us-east-1"
      profile = "aier-dev"
    }
    staging = {
      region = "us-east-1"
      profile = "aier-staging"
    }
    prod = {
      region = "us-east-1"
      profile = "aier-prod"
    }
  }
}

# AWS Provider configuration based on environment
provider "aws" {
  region  = local.provider_configs[var.environment].region
  profile = local.provider_configs[var.environment].profile

  # Security configurations
  assume_role {
    role_arn = var.enable_iam_roles ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TerraformExecutionRole" : null
  }

  # Default tags for resource tracking and cost allocation
  default_tags {
    tags = {
      Project         = "AI-ER-Capstone"
      Environment     = var.environment
      ManagedBy       = "Terraform"
      Sprint          = "2"
      CreatedBy       = "aier-team"
      Confidentiality = "Internal"
      Compliance      = var.compliance_framework
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Backend configuration for state management
terraform {
  backend "s3" {
    bucket         = "aier-terraform-state-${data.aws_caller_identity.current.account_id}"
    key            = "sprint2/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "aier-terraform-locks"

    # Security: Enable versioning and access logging
    versioning {
      enabled = true
    }

    # Access logging for audit trails
    logging {
      target_bucket = "aier-access-logs-${data.aws_caller_identity.current.account_id}"
      target_prefix = "terraform-state/"
    }
  }
}
