provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/sprint4/app-logs"
  retention_in_days = 7
}

resource "aws_iam_role" "lambda_role" {
  name = "sprint4-lambda-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

