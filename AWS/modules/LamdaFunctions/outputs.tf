output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.lambda_function.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda_function.function_name
}

output "lambda_function_invoke_arn" {
  description = "ARN to be used for invoking Lambda function from API Gateway"
  value       = aws_lambda_function.lambda_function.invoke_arn
}

output "lambda_function_version" {
  description = "Latest published version of your Lambda function"
  value       = aws_lambda_function.lambda_function.version
}

output "lambda_function_last_modified" {
  description = "Date this resource was last modified"
  value       = aws_lambda_function.lambda_function.last_modified
}

output "lambda_function_qualified_arn" {
  description = "Qualified ARN (ARN with lambda version number)"
  value       = aws_lambda_function.lambda_function.qualified_arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role created for Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the IAM role created for Lambda function"
  value       = aws_iam_role.lambda_role.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda alias (if created)"
  value       = var.create_alias ? aws_lambda_alias.lambda_alias[0].arn : null
}
