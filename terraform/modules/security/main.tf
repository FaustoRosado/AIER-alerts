# AI/ER Capstone Project - Security Module
# Sprint 2: Security Controls and IAM

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "allow_ssh_from" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = []
}

variable "allow_https_from" {
  description = "CIDR blocks allowed to access HTTPS"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Security Groups

# LLM Server Security Group (Private subnet)
resource "aws_security_group" "llm_server" {
  name_prefix = "${var.name_prefix}-llm-server"
  description = "Security group for LLM server instances"
  vpc_id      = var.vpc_id

  # Inbound rules (restrictive by default)
  ingress {
    description = "SSH from bastion only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "Flask application port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Only from within VPC
  }

  # Outbound rules (restrictive)
  egress {
    description = "HTTPS for package updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-llm-server-sg"
  })
}

# Bastion Host Security Group (Public subnet)
resource "aws_security_group" "bastion" {
  name_prefix = "${var.name_prefix}-bastion"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # Inbound rules
  dynamic "ingress" {
    for_each = length(var.allow_ssh_from) > 0 ? [1] : []
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allow_ssh_from
    }
  }

  # Outbound rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-sg"
  })
}

# IAM Roles and Policies

# IAM role for LLM server instances
resource "aws_iam_role" "llm_server" {
  name = "${var.name_prefix}-llm-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  # Attach security policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-llm-server-role"
  })
}

# Custom policy for LLM server (principle of least privilege)
resource "aws_iam_role_policy" "llm_server_policy" {
  name = "${var.name_prefix}-llm-server-policy"
  role = aws_iam_role.llm_server.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/llm-server/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile for LLM server
resource "aws_iam_instance_profile" "llm_server" {
  name = "${var.name_prefix}-llm-server-profile"
  role = aws_iam_role.llm_server.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-llm-server-profile"
  })
}

# KMS Key for encryption (if enabled)
resource "aws_kms_key" "llm_server" {
  description             = "KMS key for LLM server encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-llm-key"
  })
}

# CloudWatch Log Group for LLM server
resource "aws_cloudwatch_log_group" "llm_server" {
  name              = "/aws/llm-server/${var.name_prefix}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.llm_server.arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-llm-logs"
  })
}

# Outputs
output "llm_server_sg_id" {
  description = "ID of the LLM server security group"
  value       = aws_security_group.llm_server.id
}

output "bastion_sg_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "llm_server_profile_name" {
  description = "Name of the LLM server instance profile"
  value       = aws_iam_instance_profile.llm_server.name
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.llm_server.arn
}
