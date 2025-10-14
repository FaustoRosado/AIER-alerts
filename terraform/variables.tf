# AI/ER Capstone Project - Terraform Variables
# Sprint 2: Infrastructure as Code Configuration

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-east-2", "us-west-1", "us-west-2", "eu-west-1"], var.aws_region)
    error_message = "Region must be a valid AWS region with appropriate compliance certifications."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "sandbox"

  validation {
    condition     = contains(["dev", "staging", "sandbox", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, sandbox, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aier-capstone"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase, alphanumeric, and under 20 characters."
  }
}

variable "instance_type" {
  description = "EC2 instance type for LLM server"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "c5.large", "c5.xlarge"], var.instance_type)
    error_message = "Instance type must be appropriate for LLM workloads."
  }
}

variable "key_pair_name" {
  description = "Name of the SSH key pair for EC2 access"
  type        = string
  default     = null

  validation {
    condition     = var.key_pair_name == null || can(regex("^[a-zA-Z0-9-]+$", var.key_pair_name))
    error_message = "Key pair name must be alphanumeric with dashes only."
  }
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Should be restricted in production

  validation {
    condition = alltrue([
      for cidr in var.admin_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All admin CIDR blocks must be valid CIDR notation."
  }
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 30
    error_message = "Backup retention must be between 1 and 30 days."
  }
}

# Security-focused variables
variable "enable_encryption" {
  description = "Enable encryption for all storage resources"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for threat detection"
  type        = bool
  default     = true
}

# Cost optimization variables
variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

# Compliance variables
variable "compliance_framework" {
  description = "Compliance framework to adhere to"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "soc2", "hipaa", "pci-dss", "fedramp"], var.compliance_framework)
    error_message = "Compliance framework must be one of: none, soc2, hipaa, pci-dss, fedramp."
  }
}
