# AI/ER Capstone Project - Compute Module
# Sprint 2: EC2 Instances and Auto Scaling

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Map of subnet IDs"
  type = object({
    public  = string
    private = string
  })
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# LLM Server Instance (Private subnet)
resource "aws_instance" "llm_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids.private
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_pair_name

  # Security: Enable monitoring and detailed logging
  monitoring = true

  # Storage configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    kms_key_id           = data.aws_kms_key.default.arn
    delete_on_termination = true

    tags = merge(var.tags, {
      Name = "${var.name_prefix}-llm-server-root"
    })
  }

  # User data script for LLM server setup
  user_data = templatefile("${path.module}/../../scripts/llm-server-setup.sh", {
    server_name = "${var.name_prefix}-llm-server"
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-llm-server"
    Type = "LLM-Server"
  })
}

# Bastion Host Instance (Public subnet)
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro" # Cost-effective for bastion
  subnet_id              = var.subnet_ids.public
  vpc_security_group_ids = [var.security_group_ids[1]] # Bastion security group
  key_name               = var.key_pair_name

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    kms_key_id           = data.aws_kms_key.default.arn
    delete_on_termination = true

    tags = merge(var.tags, {
      Name = "${var.name_prefix}-bastion-root"
    })
  }

  # User data for bastion setup
  user_data = templatefile("${path.module}/../../scripts/bastion-setup.sh", {
    server_name = "${var.name_prefix}-bastion"
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
    Type = "Bastion-Host"
  })
}

# Data sources
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_kms_key" "default" {
  key_id = "alias/aws/ebs"
}

# Auto Scaling Group for LLM servers (for future scalability)
resource "aws_launch_template" "llm_server" {
  name_prefix   = "${var.name_prefix}-llm-server"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      kms_key_id           = data.aws_kms_key.default.arn
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/../../scripts/llm-server-setup.sh", {
    server_name = "${var.name_prefix}-llm-server"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-llm-server"
      Type = "LLM-Server"
    })
  }
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "llm_server_cpu" {
  alarm_name          = "${var.name_prefix}-llm-server-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors LLM server CPU utilization"
  alarm_actions       = [] # Add SNS topic for notifications

  dimensions = {
    InstanceId = aws_instance.llm_server.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-llm-server-cpu-alarm"
  })
}

# Outputs
output "llm_server_instance_id" {
  description = "Instance ID of the LLM server"
  value       = aws_instance.llm_server.id
}

output "llm_server_private_ip" {
  description = "Private IP of the LLM server"
  value       = aws_instance.llm_server.private_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "launch_template_id" {
  description = "ID of the LLM server launch template"
  value       = aws_launch_template.llm_server.id
}
