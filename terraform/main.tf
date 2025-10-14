terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment   = var.environment
      Project       = "AI-ER-Capstone"
      ManagedBy     = "Terraform"
      Sprint        = "2"
      Confidentiality = "Internal"
    }
  }
}

# Local variables for security and consistency
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Security configurations
  enable_encryption = true
  enable_logging   = true

  # Network configurations
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidrs = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }
  private_subnet_cidrs = {
    "us-east-1a" = "10.0.101.0/24"
    "us-east-1b" = "10.0.102.0/24"
  }
}

# Call VPC module
module "vpc" {
  source = "./modules/vpc"

  name_prefix = local.name_prefix
  vpc_cidr   = local.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Purpose = "Secure network foundation for AI/ER local LLM system"
  }
}

# Call Security module
module "security" {
  source = "./modules/security"

  name_prefix = local.name_prefix
  vpc_id     = module.vpc.vpc_id
  vpc_cidr   = local.vpc_cidr

  # Security group configurations
  allow_ssh_from = var.admin_cidr_blocks
  allow_https_from = ["0.0.0.0/0"] # Will be restricted in production

  tags = {
    Purpose = "Security controls for AI/ER capstone project"
  }
}

# Call Compute module
module "compute" {
  source = "./modules/compute"

  name_prefix = local.name_prefix
  vpc_id     = module.vpc.vpc_id
  subnet_ids = {
    public  = values(module.vpc.public_subnet_ids)[0]
    private = values(module.vpc.private_subnet_ids)[0]
  }

  # Instance configurations
  instance_type = var.instance_type
  key_pair_name = var.key_pair_name

  # Security configurations
  security_group_ids = [
    module.security.llm_server_sg_id,
    module.security.bastion_sg_id
  ]

  # IAM configurations
  iam_instance_profile = module.security.llm_server_profile_name

  tags = {
    Purpose = "Compute resources for local LLM deployment"
  }
}

# Output important resource identifiers
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = values(module.vpc.public_subnet_ids)[0]
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = values(module.vpc.private_subnet_ids)[0]
}

output "llm_server_instance_id" {
  description = "Instance ID of the LLM server"
  value       = module.compute.llm_server_instance_id
}

output "llm_server_private_ip" {
  description = "Private IP of the LLM server"
  value       = module.compute.llm_server_private_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host"
  value       = module.compute.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.compute.bastion_public_ip
}
