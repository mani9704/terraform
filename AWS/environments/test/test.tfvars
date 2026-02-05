# Lambda Function Configuration - Test Environment
function_name = "test-lambda-function"
handler       = "index.handler"
runtime       = "python3.11"

# Deployment Package - Choose one:
# Option 1: Local file
filename = "lambda_function.zip"

# Option 2: S3 (uncomment if using S3)
# s3_bucket = "my-lambda-deployments-bucket"
# s3_key    = "lambda_function.zip"

# Function Configuration
timeout     = 30
memory_size = 256
description = "Test Lambda function"

# Environment Variables
environment_variables = {
  ENV         = "test"
  LOG_LEVEL   = "DEBUG"
  API_ENDPOINT = "https://test-api.example.com"
}

# VPC Configuration (optional - uncomment if needed)
# vpc_subnet_ids         = ["subnet-12345", "subnet-67890"]
# vpc_security_group_ids = ["sg-12345"]

# Dead Letter Queue (optional)
# dead_letter_target_arn = "arn:aws:sqs:us-east-1:123456789012:test-dlq"

# Tracing
tracing_mode = "PassThrough"

# Lambda Layers (optional)
# layers = ["arn:aws:lambda:us-east-1:123456789012:layer:my-layer:1"]

# Versioning
publish = false

# Log Retention
log_retention_days = 7

# Additional IAM Policies (optional)
# additional_policy_statements = [
#   {
#     Effect   = "Allow"
#     Action   = ["s3:GetObject"]
#     Resource = ["arn:aws:s3:::my-bucket/*"]
#   }
# ]

# Lambda Alias (optional)
create_alias     = false
alias_name       = "test"
alias_description = "Test environment alias"

# Lambda Permissions for API Gateway or EventBridge (optional)
# lambda_permissions = {
#   api_gateway = {
#     action    = "lambda:InvokeFunction"
#     principal = "apigateway.amazonaws.com"
#     source_arn = "arn:aws:execute-api:us-east-1:123456789012:abc123def4/*/*"
#   }
# }

# Common Tags
common_tags = {
  Project     = "AWS-Lambda"
  ManagedBy   = "Terraform"
  Environment = "test"
  Team        = "DevOps"
}
