# AIER Alert System - Main Terraform Configuration
# Infrastructure for frontend visualization and data pipeline

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration for remote state storage
  # Commented out for initial demo - uses local state
  # Uncomment after creating S3 bucket for state storage
  # backend "s3" {
  #   bucket = "aier-terraform-state"
  #   key    = "frontend-viz/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "AIER-Alert-System"
      Component   = "Frontend-Visualization"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Team        = "Cyber-Security-Fellowship"
    }
  }
}

# Data for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 Bucket for Data Storage
resource "aws_s3_bucket" "data_storage" {
  bucket = "${var.project_name}-data-${var.environment}"
  
  tags = {
    Name = "AIER Data Storage"
  }
}

# Enable versioning for data bucket
resource "aws_s3_bucket_versioning" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for data bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to data bucket
resource "aws_s3_bucket_public_access_block" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Frontend Static Files
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"
  
  tags = {
    Name = "AIER Frontend"
  }
}

# Enable website hosting for frontend bucket
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "error.html"
  }
}

# DynamoDB Table for Patient Data
resource "aws_dynamodb_table" "patient_data" {
  name           = "${var.project_name}-patient-data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "patient_id"
  range_key      = "timestamp"
  
  attribute {
    name = "patient_id"
    type = "S"
  }
  
  attribute {
    name = "timestamp"
    type = "N"
  }
  
  attribute {
    name = "risk_level"
    type = "S"
  }
  
  attribute {
    name = "age_group"
    type = "S"
  }
  
  # Global Secondary Index for risk level queries
  global_secondary_index {
    name            = "RiskLevelIndex"
    hash_key        = "risk_level"
    range_key       = "timestamp"
    projection_type = "ALL"
  }
  
  # Global Secondary Index for age group queries
  global_secondary_index {
    name            = "AgeGroupIndex"
    hash_key        = "age_group"
    range_key       = "timestamp"
    projection_type = "ALL"
  }
  
  tags = {
    Name = "AIER Patient Data"
  }
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-lambda-execution"
  
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
  
  tags = {
    Name = "AIER Lambda Execution Role"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_execution.id
  
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
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.data_storage.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.patient_data.arn
      }
    ]
  })
}

# Lambda Function for Data Processing
resource "aws_lambda_function" "data_processor" {
  filename      = "${path.module}/../backend/lambda_function.zip"
  function_name = "${var.project_name}-data-processor"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 512
  
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.patient_data.name
      S3_BUCKET_NAME      = aws_s3_bucket.data_storage.id
    }
  }
  
  tags = {
    Name = "AIER Data Processor"
  }
}

# S3 Bucket Notification to Trigger Lambda
resource "aws_s3_bucket_notification" "data_upload" {
  bucket = aws_s3_bucket.data_storage.id
  
  lambda_function {
    lambda_function_arn = aws_lambda_function.data_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "processed/"
    filter_suffix       = ".csv"
  }
}

# Lambda Permission for S3
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_storage.arn
}

# CloudFront Distribution for Frontend
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = {
    Name = "AIER Frontend Distribution"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.data_processor.function_name}"
  retention_in_days = 7
  
  tags = {
    Name = "AIER Lambda Logs"
  }
}

# Outputs
output "data_bucket_name" {
  description = "S3 bucket name for data storage"
  value       = aws_s3_bucket.data_storage.id
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend files"
  value       = aws_s3_bucket.frontend.id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for patient data"
  value       = aws_dynamodb_table.patient_data.name
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.data_processor.function_name
}
