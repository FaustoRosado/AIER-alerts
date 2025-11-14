# ============================================================================
# Sprint 3 Automation Infrastructure
# Following "Concepts & Synchronizations" Pattern
# 
# This Terraform code is structured to match the logical architecture:
# 1. Concepts (Lambda functions) - independent services
# 2. Synchronizations (EventBridge rules) - event-based connectors
# 3. Orchestration (Step Functions) - visible workflows
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Sprint3-Automation"
      ManagedBy   = "Terraform"
      Purpose     = "DevSecOps Automation"
      Pattern     = "Concepts-Synchronizations"
    }
  }
}

# ============================================================================
# VARIABLES - Configuration
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
  default     = "sprint3-automation"
}

# ============================================================================
# CONCEPT 1: Pipeline Validator Lambda
# Purpose: Validates CI/CD pipeline execution results
# ============================================================================

resource "aws_iam_role" "pipeline_validator_role" {
  name = "${var.project_name}-pipeline-validator-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "pipeline_validator_basic" {
  role       = aws_iam_role.pipeline_validator_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "pipeline_validator_policy" {
  name = "${var.project_name}-pipeline-validator-policy"
  role = aws_iam_role.pipeline_validator_role.id
  
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
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.devops_notifications.arn
      }
    ]
  })
}

# Package Lambda function code
data "archive_file" "pipeline_validator" {
  type        = "zip"
  source_file = "${path.module}/../concepts/pipeline-validator/handler.py"
  output_path = "${path.module}/lambda-packages/pipeline-validator.zip"
}

resource "aws_lambda_function" "pipeline_validator" {
  filename         = data.archive_file.pipeline_validator.output_path
  function_name    = "${var.project_name}-pipeline-validator"
  role            = aws_iam_role.pipeline_validator_role.arn
  handler         = "handler.handler"
  source_code_hash = data.archive_file.pipeline_validator.output_base64sha256
  runtime         = "python3.11"
  timeout         = 60
  
  environment {
    variables = {
      LOG_GROUP     = "/aws/lambda/${var.project_name}-pipeline-validator"
      SNS_TOPIC_ARN = aws_sns_topic.devops_notifications.arn
    }
  }
  
  description = "Concept: Validates pipeline execution results"
}

# ============================================================================
# CONCEPT 2: Drift Detector Lambda
# Purpose: Detects infrastructure drift from Terraform state
# ============================================================================

resource "aws_iam_role" "drift_detector_role" {
  name = "${var.project_name}-drift-detector-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "drift_detector_basic" {
  role       = aws_iam_role.drift_detector_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "drift_detector_policy" {
  name = "${var.project_name}-drift-detector-policy"
  role = aws_iam_role.drift_detector_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "config:DescribeConfigRules",
          "config:GetComplianceDetailsByConfigRule",
          "config:GetResourceConfigHistory"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "drift_detector" {
  type        = "zip"
  source_file = "${path.module}/../concepts/drift-detector/handler.py"
  output_path = "${path.module}/lambda-packages/drift-detector.zip"
}

resource "aws_lambda_function" "drift_detector" {
  filename         = data.archive_file.drift_detector.output_path
  function_name    = "${var.project_name}-drift-detector"
  role            = aws_iam_role.drift_detector_role.arn
  handler         = "handler.handler"
  source_code_hash = data.archive_file.drift_detector.output_base64sha256
  runtime         = "python3.11"
  timeout         = 60
  
  environment {
    variables = {
      TERRAFORM_STATE_BUCKET = "your-terraform-state-bucket"
      TERRAFORM_STATE_KEY    = "terraform.tfstate"
    }
  }
  
  description = "Concept: Detects infrastructure drift"
}

# ============================================================================
# CONCEPT 3: Auto Remediator Lambda
# Purpose: Automatically fixes detected drift
# ============================================================================

resource "aws_iam_role" "auto_remediator_role" {
  name = "${var.project_name}-auto-remediator-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "auto_remediator_basic" {
  role       = aws_iam_role.auto_remediator_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "auto_remediator_policy" {
  name = "${var.project_name}-auto-remediator-policy"
  role = aws_iam_role.auto_remediator_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.devops_notifications.arn
      }
    ]
  })
}

data "archive_file" "auto_remediator" {
  type        = "zip"
  source_file = "${path.module}/../concepts/auto-remediator/handler.py"
  output_path = "${path.module}/lambda-packages/auto-remediator.zip"
}

resource "aws_lambda_function" "auto_remediator" {
  filename         = data.archive_file.auto_remediator.output_path
  function_name    = "${var.project_name}-auto-remediator"
  role            = aws_iam_role.auto_remediator_role.arn
  handler         = "handler.handler"
  source_code_hash = data.archive_file.auto_remediator.output_base64sha256
  runtime         = "python3.11"
  timeout         = 300
  
  environment {
    variables = {
      TERRAFORM_CODEBUILD_PROJECT = "terraform-apply-project"
      SNS_TOPIC_ARN              = aws_sns_topic.devops_notifications.arn
      DRY_RUN                    = "false"
    }
  }
  
  description = "Concept: Automatically remediates drift"
}

# ============================================================================
# SYNCHRONIZATION 1: Pipeline Failure EventBridge Rule
# Connects: CodePipeline events -> Pipeline Validator
# ============================================================================

resource "aws_cloudwatch_event_rule" "pipeline_state_change" {
  name        = "${var.project_name}-pipeline-state-change"
  description = "Synchronization: Triggers when pipeline state changes"
  
  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      state = ["FAILED", "SUCCEEDED"]
    }
  })
  
  tags = {
    Synchronization = "PipelineFailureSync"
    Purpose         = "Event-based rule connecting CodePipeline to PipelineValidator"
  }
}

resource "aws_cloudwatch_event_target" "pipeline_to_validator" {
  rule      = aws_cloudwatch_event_rule.pipeline_state_change.name
  target_id = "InvokePipelineValidator"
  arn       = aws_lambda_function.pipeline_validator.arn
}

resource "aws_lambda_permission" "allow_eventbridge_pipeline" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pipeline_validator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pipeline_state_change.arn
}

# ============================================================================
# SYNCHRONIZATION 2: Drift Detection EventBridge Rule
# Connects: AWS Config -> Drift Detector -> Auto Remediator
# ============================================================================

resource "aws_cloudwatch_event_rule" "config_compliance_change" {
  name        = "${var.project_name}-config-compliance-change"
  description = "Synchronization: Triggers when Config detects compliance change"
  
  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
  
  tags = {
    Synchronization = "DriftDetectionSync"
    Purpose         = "Event-based rule connecting Config to DriftDetector"
  }
}

resource "aws_cloudwatch_event_target" "config_to_drift_detector" {
  rule      = aws_cloudwatch_event_rule.config_compliance_change.name
  target_id = "InvokeDriftDetector"
  arn       = aws_lambda_function.drift_detector.arn
}

resource "aws_lambda_permission" "allow_eventbridge_config" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.drift_detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.config_compliance_change.arn
}

# Second stage: Drift detected -> Auto remediation
resource "aws_cloudwatch_event_rule" "drift_to_remediation" {
  name        = "${var.project_name}-drift-to-remediation"
  description = "Synchronization: Triggers auto-remediation when drift detected"
  
  event_pattern = jsonencode({
    source      = ["custom.drift-detector"]
    detail-type = ["Drift Detected"]
    detail = {
      is_drift             = [true]
      requires_remediation = [true]
    }
  })
}

resource "aws_cloudwatch_event_target" "drift_to_remediator" {
  rule      = aws_cloudwatch_event_rule.drift_to_remediation.name
  target_id = "InvokeAutoRemediator"
  arn       = aws_lambda_function.auto_remediator.arn
}

resource "aws_lambda_permission" "allow_eventbridge_drift" {
  statement_id  = "AllowExecutionFromDriftDetector"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_remediator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.drift_to_remediation.arn
}

# ============================================================================
# ORCHESTRATION: Step Functions State Machine
# Purpose: Coordinates complex multi-step incident response
# ============================================================================

resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-step-functions-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-step-functions-policy"
  role = aws_iam_role.step_functions_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.pipeline_validator.arn,
          aws_lambda_function.drift_detector.arn,
          aws_lambda_function.auto_remediator.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.devops_notifications.arn,
          aws_sns_topic.security_alerts.arn
        ]
      }
    ]
  })
}

# Read state machine definition and substitute variables
locals {
  state_machine_definition = replace(
    replace(
      file("${path.module}/../orchestration/incident-response-state-machine.json"),
      "$${AWS_ACCOUNT}",
      data.aws_caller_identity.current.account_id
    ),
    "$${AWS_REGION}",
    var.aws_region
  )
}

data "aws_caller_identity" "current" {}

resource "aws_sfn_state_machine" "incident_response" {
  name     = "${var.project_name}-incident-response"
  role_arn = aws_iam_role.step_functions_role.arn
  
  definition = local.state_machine_definition
  
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
  
  tags = {
    Orchestration = "IncidentResponse"
    Purpose       = "Visible multi-step workflow for incident handling"
  }
}

resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "/aws/vendedlogs/states/${var.project_name}-incident-response"
  retention_in_days = 30
}

# ============================================================================
# SNS TOPICS - Notification Channels
# These decouple alert generation from delivery (pub/sub pattern)
# ============================================================================

resource "aws_sns_topic" "devops_notifications" {
  name = "${var.project_name}-devops-notifications"
  
  tags = {
    Purpose = "General DevOps notifications"
  }
}

resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts"
  
  tags = {
    Purpose = "Critical security alerts"
  }
}

resource "aws_sns_topic" "ops_alerts" {
  name = "${var.project_name}-ops-alerts"
  
  tags = {
    Purpose = "Operational alerts requiring manual intervention"
  }
}

# Example subscription (add your email)
resource "aws_sns_topic_subscription" "devops_email" {
  topic_arn = aws_sns_topic.devops_notifications.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"  # Change this!
}

# ============================================================================
# OUTPUTS - Important ARNs and URLs
# ============================================================================

output "pipeline_validator_arn" {
  description = "ARN of Pipeline Validator Lambda (Concept 1)"
  value       = aws_lambda_function.pipeline_validator.arn
}

output "drift_detector_arn" {
  description = "ARN of Drift Detector Lambda (Concept 2)"
  value       = aws_lambda_function.drift_detector.arn
}

output "auto_remediator_arn" {
  description = "ARN of Auto Remediator Lambda (Concept 3)"
  value       = aws_lambda_function.auto_remediator.arn
}

output "state_machine_arn" {
  description = "ARN of Incident Response State Machine (Orchestration)"
  value       = aws_sfn_state_machine.incident_response.arn
}

output "state_machine_console_url" {
  description = "URL to view Step Functions in AWS Console (WHAT YOU SEE IS WHAT IT DOES)"
  value       = "https://console.aws.amazon.com/states/home?region=${var.aws_region}#/statemachines/view/${aws_sfn_state_machine.incident_response.arn}"
}

output "eventbridge_rules" {
  description = "EventBridge rules (Synchronizations) connecting concepts"
  value = {
    pipeline_sync = aws_cloudwatch_event_rule.pipeline_state_change.name
    drift_sync    = aws_cloudwatch_event_rule.config_compliance_change.name
  }
}

