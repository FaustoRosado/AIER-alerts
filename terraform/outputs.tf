# AI/ER Capstone Project - Terraform Outputs
# Sprint 2: Infrastructure Outputs and Documentation

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    project_name   = var.project_name
    environment    = var.environment
    region         = var.aws_region
    vpc_cidr       = local.vpc_cidr
    compliance     = var.compliance_framework
    created_date   = timestamp()
  }
}

output "networking" {
  description = "Network infrastructure details"
  value = {
    vpc_id           = module.vpc.vpc_id
    vpc_cidr_block   = module.vpc.vpc_cidr_block
    public_subnets   = module.vpc.public_subnet_ids
    private_subnets  = module.vpc.private_subnet_ids
    internet_gateway = module.vpc.internet_gateway_id
    nat_gateways     = module.vpc.nat_gateway_ids
  }
}

output "security" {
  description = "Security infrastructure details"
  value = {
    llm_server_security_group = module.security.llm_server_sg_id
    bastion_security_group    = module.security.bastion_sg_id
    iam_instance_profile      = module.security.llm_server_profile_name
    key_pair_name             = var.key_pair_name
  }
}

output "compute" {
  description = "Compute infrastructure details"
  value = {
    llm_server_instance_id  = module.compute.llm_server_instance_id
    llm_server_private_ip   = module.compute.llm_server_private_ip
    bastion_instance_id     = module.compute.bastion_instance_id
    bastion_public_ip       = module.compute.bastion_public_ip
  }
}

output "access_information" {
  description = "Important access information for administrators"
  sensitive   = true
  value = {
    ssh_access = {
      bastion_host      = module.compute.bastion_public_ip
      key_pair_required = var.key_pair_name != null
      allowed_cidrs     = var.admin_cidr_blocks
    }
    llm_server = {
      private_ip       = module.compute.llm_server_private_ip
      instance_id      = module.compute.llm_server_instance_id
      access_via       = "bastion_host"
    }
  }
}

output "cost_optimization" {
  description = "Cost optimization recommendations"
  value = {
    estimated_monthly_cost = "Varies based on usage"
    optimization_tips = [
      "Use t3.medium instances for development",
      "Enable auto-scaling for production workloads",
      "Use spot instances for non-critical workloads",
      "Set up budget alerts in AWS Cost Explorer",
      "Use lifecycle policies for data retention"
    ]
  }
}

output "security_recommendations" {
  description = "Security best practices and next steps"
  value = {
    immediate_actions = [
      "Rotate SSH key pairs regularly",
      "Set up CloudWatch alarms for security events",
      "Configure log aggregation and monitoring",
      "Implement regular security assessments"
    ]
    compliance_notes = var.compliance_framework != "none" ? [
      "Ensure ${var.compliance_framework} compliance requirements are met",
      "Set up regular compliance audits",
      "Document security controls and procedures"
    ] : []
    monitoring_setup = [
      "Configure CloudTrail for API logging",
      "Set up GuardDuty for threat detection",
      "Enable VPC Flow Logs for network monitoring",
      "Configure CloudWatch for system metrics"
    ]
  }
}

output "disaster_recovery" {
  description = "Disaster recovery information"
  value = {
    backup_strategy = "Automated snapshots and AMIs"
    recovery_time   = "Approximately 5-10 minutes for instance recovery"
    data_retention  = "${var.backup_retention_days} days"
    recovery_steps = [
      "1. Use Terraform to recreate infrastructure",
      "2. Restore data from latest snapshots",
      "3. Update DNS and load balancer configurations",
      "4. Test application functionality"
    ]
  }
}

# Export values for use by other configurations
resource "local_file" "terraform_outputs" {
  filename = "${path.module}/../outputs/terraform-outputs.json"
  content  = jsonencode({
    vpc_id           = module.vpc.vpc_id
    public_subnet_id = values(module.vpc.public_subnet_ids)[0]
    private_subnet_id = values(module.vpc.private_subnet_ids)[0]
    llm_server_sg_id = module.security.llm_server_sg_id
    bastion_sg_id    = module.security.bastion_sg_id
  })
}
