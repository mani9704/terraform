# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}_role"

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

  tags = var.tags
}

# IAM Policy for Lambda to write to CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.function_name}_logging_policy"
  role = aws_iam_role.lambda_role.id

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
      }
    ]
  })
}

# Additional IAM Policy Attachment (if custom policies are provided)
resource "aws_iam_role_policy" "lambda_custom" {
  count  = length(var.additional_policy_statements) > 0 ? 1 : 0
  name   = "${var.function_name}_custom_policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.additional_policy_statements
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda Function
resource "aws_lambda_function" "lambda_function" {
  filename         = var.filename != null ? var.filename : null
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  s3_object_version = var.s3_object_version
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  source_code_hash = var.filename != null ? filebase64sha256(var.filename) : null
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  description      = var.description
  publish          = var.publish
  layers           = var.layers

  environment {
    variables = var.environment_variables
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  dead_letter_config {
    target_arn = var.dead_letter_target_arn
  }

  tracing_config {
    mode = var.tracing_mode
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.lambda_logging,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# Lambda Function Alias (optional)
resource "aws_lambda_alias" "lambda_alias" {
  count            = var.create_alias ? 1 : 0
  name             = var.alias_name
  description      = var.alias_description
  function_name    = aws_lambda_function.lambda_function.function_name
  function_version = var.alias_version != null ? var.alias_version : aws_lambda_function.lambda_function.version
}

# Lambda Permission for API Gateway or other triggers (optional)
resource "aws_lambda_permission" "lambda_permission" {
  for_each      = var.lambda_permissions
  statement_id  = each.key
  action        = each.value.action
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = each.value.principal
  source_arn    = lookup(each.value, "source_arn", null)
  qualifier     = lookup(each.value, "qualifier", null)
}
