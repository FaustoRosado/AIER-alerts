# ============================================================================
# Zero-Trust Hybrid AI Pipeline - AWS Cloud Plane Infrastructure
# ============================================================================
#
# This Terraform configuration deploys the cloud-side infrastructure:
#   • ECR repositories for container images
#   • CodePipeline for CI/CD automation
#   • Lambda functions for serverless processing
#   • API Gateway for external webhooks
#   • S3 for audit logs and artifacts
#   • CloudWatch for monitoring
#
# The cloud plane handles ONLY:
#   • DevSecOps automation (no PHI)
#   • Security scanning
#   • Deployment orchestration
#   • Audit log aggregation (anonymized)
#
# PHI processing remains strictly on local infrastructure.
#
# Usage:
#   cd terraform/environments/dev
#   terraform init
#   terraform plan
#   terraform apply
#
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Uncomment for remote state (recommended for production)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "zero-trust-hybrid-ai/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ZeroTrustHybridAI"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CostCenter  = "AI-Infrastructure"
    }
  }
}

# ============================================================================
# Variables
# ============================================================================

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "zero-trust-ai"
}

variable "github_repo" {
  description = "GitHub repository (owner/repo format)"
  type        = string
  default     = "your-org/zero-trust-hybrid-ai"
}

variable "github_branch" {
  description = "GitHub branch to track"
  type        = string
  default     = "main"
}

variable "enable_security_scanning" {
  description = "Enable security scanning in pipeline"
  type        = bool
  default     = true
}

# ============================================================================
# Random suffix for unique naming
# ============================================================================

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  name_suffix = random_id.suffix.hex
}

# ============================================================================
# S3 Buckets
# ============================================================================

# Artifact bucket for CodePipeline
resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name_prefix}-artifacts-${local.name_suffix}"

  tags = {
    Name = "Pipeline Artifacts"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Audit logs bucket
resource "aws_s3_bucket" "audit_logs" {
  bucket = "${local.name_prefix}-audit-logs-${local.name_suffix}"

  tags = {
    Name        = "Audit Logs"
    Compliance  = "HIPAA-Adjacent"
    DataClass   = "NoPatientData"
  }
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    # HIPAA requires 6-year retention
    expiration {
      days = 2190  # 6 years
    }
  }
}

# ============================================================================
# ECR Repository
# ============================================================================

resource "aws_ecr_repository" "orchestrator" {
  name                 = "${local.name_prefix}-orchestrator"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Name = "Orchestrator Container"
  }
}

resource "aws_ecr_lifecycle_policy" "orchestrator" {
  repository = aws_ecr_repository.orchestrator.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ============================================================================
# IAM Roles
# ============================================================================

# CodePipeline service role
resource "aws_iam_role" "codepipeline" {
  name = "${local.name_prefix}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${local.name_prefix}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}

# CodeBuild service role
resource "aws_iam_role" "codebuild" {
  name = "${local.name_prefix}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${local.name_prefix}-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda execution role
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_s3" {
  name = "${local.name_prefix}-lambda-s3-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.audit_logs.arn}/*"
        ]
      }
    ]
  })
}

# ============================================================================
# GitHub Connection (CodeStar)
# ============================================================================

resource "aws_codestarconnections_connection" "github" {
  name          = "${local.name_prefix}-github"
  provider_type = "GitHub"
}

# ============================================================================
# CodeBuild Projects
# ============================================================================

# Security scanning project
resource "aws_codebuild_project" "security_scan" {
  count = var.enable_security_scanning ? 1 : 0

  name          = "${local.name_prefix}-security-scan"
  description   = "Security scanning with Checkov and tfsec"
  build_timeout = 15
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      phases:
        install:
          runtime-versions:
            python: 3.11
          commands:
            - pip install checkov
            - curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
        build:
          commands:
            - echo "Running Checkov security scan..."
            - checkov -d . --soft-fail --output cli --output junitxml --output-file-path . || true
            - echo "Running tfsec..."
            - tfsec . --soft-fail --format json --out tfsec-results.json || true
        post_build:
          commands:
            - echo "Security scan complete"
            - cat results_junitxml.xml || true
      artifacts:
        files:
          - results_junitxml.xml
          - tfsec-results.json
        discard-paths: yes
      reports:
        security-report:
          files:
            - results_junitxml.xml
          file-format: JUNITXML
    EOF
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${local.name_prefix}-security-scan"
      stream_name = "build-log"
    }
  }

  tags = {
    Name = "Security Scanning"
  }
}

# Container build project
resource "aws_codebuild_project" "container_build" {
  name          = "${local.name_prefix}-container-build"
  description   = "Build and push container images"
  build_timeout = 30
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ECR_REPO_URL"
      value = aws_ecr_repository.orchestrator.repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
            - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
            - IMAGE_TAG=$${COMMIT_HASH:=latest}
        build:
          commands:
            - echo Building container image...
            - cd orchestrator
            - docker build -t $ECR_REPO_URL:$IMAGE_TAG .
            - docker tag $ECR_REPO_URL:$IMAGE_TAG $ECR_REPO_URL:latest
        post_build:
          commands:
            - echo Pushing container image...
            - docker push $ECR_REPO_URL:$IMAGE_TAG
            - docker push $ECR_REPO_URL:latest
            - echo Writing image definitions file...
            - printf '[{"name":"orchestrator","imageUri":"%s"}]' $ECR_REPO_URL:$IMAGE_TAG > imagedefinitions.json
      artifacts:
        files:
          - imagedefinitions.json
    EOF
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${local.name_prefix}-container-build"
      stream_name = "build-log"
    }
  }

  tags = {
    Name = "Container Build"
  }
}

# ============================================================================
# CodePipeline
# ============================================================================

resource "aws_codepipeline" "main" {
  name     = "${local.name_prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
      }
    }
  }

  dynamic "stage" {
    for_each = var.enable_security_scanning ? [1] : []
    content {
      name = "SecurityScan"

      action {
        name             = "SecurityScan"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        output_artifacts = ["security_output"]
        version          = "1"

        configuration = {
          ProjectName = aws_codebuild_project.security_scan[0].name
        }
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildContainer"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.container_build.name
      }
    }
  }

  tags = {
    Name = "Main Pipeline"
  }
}

# ============================================================================
# Lambda Functions
# ============================================================================

# Audit log processor
data "archive_file" "audit_processor" {
  type        = "zip"
  output_path = "${path.module}/lambda/audit_processor.zip"

  source {
    content  = <<-EOF
      import json
      import boto3
      import os
      from datetime import datetime

      s3 = boto3.client('s3')
      BUCKET = os.environ.get('AUDIT_BUCKET')

      def handler(event, context):
          """
          Process audit events from local infrastructure.
          IMPORTANT: This function receives ANONYMIZED data only.
          No PHI should ever reach this endpoint.
          """
          
          # Validate no PHI markers present
          body = json.loads(event.get('body', '{}'))
          
          phi_markers = ['ssn', 'social_security', 'patient_name', 'dob', 'date_of_birth']
          for marker in phi_markers:
              if marker in json.dumps(body).lower():
                  return {
                      'statusCode': 400,
                      'body': json.dumps({
                          'error': 'PHI_DETECTED',
                          'message': 'Potential PHI detected. Request rejected.'
                      })
                  }
          
          # Store anonymized audit log
          timestamp = datetime.utcnow().isoformat()
          key = f"audit-logs/{timestamp[:10]}/{timestamp}.json"
          
          audit_record = {
              'timestamp': timestamp,
              'source': body.get('source', 'unknown'),
              'event_type': body.get('event_type', 'unknown'),
              'metadata': body.get('metadata', {}),
              'anonymized': True
          }
          
          s3.put_object(
              Bucket=BUCKET,
              Key=key,
              Body=json.dumps(audit_record),
              ContentType='application/json'
          )
          
          return {
              'statusCode': 200,
              'body': json.dumps({
                  'status': 'logged',
                  'key': key
              })
          }
    EOF
    filename = "index.py"
  }
}

resource "aws_lambda_function" "audit_processor" {
  filename         = data.archive_file.audit_processor.output_path
  function_name    = "${local.name_prefix}-audit-processor"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.audit_processor.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      AUDIT_BUCKET = aws_s3_bucket.audit_logs.bucket
    }
  }

  tags = {
    Name      = "Audit Log Processor"
    DataClass = "NoPatientData"
  }
}

# ============================================================================
# API Gateway (HTTP API - cheaper than REST)
# ============================================================================

resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }

  tags = {
    Name = "Zero-Trust API"
  }
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_integration" "audit" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.audit_processor.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "audit" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /audit"
  target    = "integrations/${aws_apigatewayv2_integration.audit.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.audit_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}

# ============================================================================
# Outputs
# ============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL for orchestrator container"
  value       = aws_ecr_repository.orchestrator.repository_url
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "audit_bucket" {
  description = "S3 bucket for audit logs"
  value       = aws_s3_bucket.audit_logs.bucket
}

output "artifacts_bucket" {
  description = "S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.artifacts.bucket
}

output "pipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.main.name
}

output "github_connection_status" {
  description = "GitHub connection status (must be AVAILABLE after manual approval)"
  value       = aws_codestarconnections_connection.github.connection_status
}

output "github_connection_arn" {
  description = "GitHub connection ARN for manual approval"
  value       = aws_codestarconnections_connection.github.arn
}
