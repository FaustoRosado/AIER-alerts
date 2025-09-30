# AIER Alert System - Terraform Variables

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "aier"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
