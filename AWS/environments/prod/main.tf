terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Lambda Function Module - Production Environment
module "lambda_function" {
  source = "../../modules/LamdaFunctions"

  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  filename      = var.filename
  s3_bucket     = var.s3_bucket
  s3_key        = var.s3_key

  timeout     = var.timeout
  memory_size = var.memory_size
  description = var.description

  environment_variables = var.environment_variables

  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids

  dead_letter_target_arn = var.dead_letter_target_arn
  tracing_mode          = var.tracing_mode
  layers                = var.layers
  publish               = var.publish

  log_retention_days = var.log_retention_days

  additional_policy_statements = var.additional_policy_statements

  create_alias     = var.create_alias
  alias_name       = var.alias_name
  alias_version    = var.alias_version
  alias_description = var.alias_description

  lambda_permissions = var.lambda_permissions

  tags = merge(
    var.common_tags,
    {
      Environment = "production"
    }
  )
}
