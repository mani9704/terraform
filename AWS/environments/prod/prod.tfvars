# Lambda Function Configuration - Production Environment
function_name = "prod-lambda-function"
handler       = "index.handler"
runtime       = "python3.11"

# Deployment Package - Choose one:
# Option 1: Local file
# filename = "lambda_function.zip"

# Option 2: S3 (recommended for production)
s3_bucket = "my-lambda-deployments-bucket-prod"
s3_key    = "lambda_function.zip"

# Function Configuration
timeout     = 60
memory_size = 512
description = "Production Lambda function"

# Environment Variables
environment_variables = {
  ENV         = "production"
  LOG_LEVEL   = "INFO"
  API_ENDPOINT = "https://api.example.com"
}

# VPC Configuration (optional - uncomment if needed)
# vpc_subnet_ids         = ["subnet-prod-12345", "subnet-prod-67890"]
# vpc_security_group_ids = ["sg-prod-12345"]

# Dead Letter Queue (recommended for production)
# dead_letter_target_arn = "arn:aws:sqs:us-east-1:123456789012:prod-dlq"

# Tracing (Active for production to enable X-Ray)
tracing_mode = "Active"

# Lambda Layers (optional)
# layers = ["arn:aws:lambda:us-east-1:123456789012:layer:my-layer:1"]

# Versioning (enabled for production)
publish = true

# Log Retention (longer retention for production)
log_retention_days = 30

# Additional IAM Policies (optional)
# additional_policy_statements = [
#   {
#     Effect   = "Allow"
#     Action   = ["s3:GetObject", "s3:PutObject"]
#     Resource = ["arn:aws:s3:::my-prod-bucket/*"]
#   }
# ]

# Lambda Alias (enabled for production)
create_alias     = true
alias_name       = "live"
alias_description = "Production environment alias"

# Lambda Permissions for API Gateway or EventBridge (optional)
# lambda_permissions = {
#   api_gateway = {
#     action    = "lambda:InvokeFunction"
#     principal = "apigateway.amazonaws.com"
#     source_arn = "arn:aws:execute-api:us-east-1:123456789012:prod-api/*/*"
#     qualifier = "live"
#   }
#   eventbridge = {
#     action    = "lambda:InvokeFunction"
#     principal = "events.amazonaws.com"
#     source_arn = "arn:aws:events:us-east-1:123456789012:rule/my-rule"
#   }
# }

# Common Tags
common_tags = {
  Project     = "AWS-Lambda"
  ManagedBy   = "Terraform"
  Environment = "production"
  Team        = "DevOps"
  CostCenter  = "Engineering"
}
