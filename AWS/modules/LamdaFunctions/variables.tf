variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda function handler (e.g., index.handler)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.11, nodejs18.x, java17)"
  type        = string
  default     = "python3.11"
}

variable "filename" {
  description = "Path to the function's deployment package (zip file). Either filename or s3_bucket/s3_key must be specified"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket name containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of an object containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Object version containing the function's deployment package"
  type        = string
  default     = null
}

variable "timeout" {
  description = "Amount of time your Lambda function has to run in seconds"
  type        = number
  default     = 3
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use at runtime"
  type        = number
  default     = 128
}

variable "description" {
  description = "Description of what your Lambda function does"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs associated with the Lambda function"
  type        = list(string)
  default     = []
}

variable "dead_letter_target_arn" {
  description = "ARN of an SQS queue or SNS topic to send failed events to"
  type        = string
  default     = null
}

variable "tracing_mode" {
  description = "Tracing mode (Active, PassThrough, Disabled)"
  type        = string
  default     = "PassThrough"
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs to attach to your Lambda function"
  type        = list(string)
  default     = []
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group"
  type        = number
  default     = 7
}

variable "additional_policy_statements" {
  description = "Additional IAM policy statements to attach to the Lambda role"
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []
}

variable "create_alias" {
  description = "Whether to create a Lambda alias"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name for the Lambda alias"
  type        = string
  default     = "live"
}

variable "alias_description" {
  description = "Description for the Lambda alias"
  type        = string
  default     = ""
}

variable "alias_version" {
  description = "Lambda function version for alias. If not specified, uses $LATEST"
  type        = string
  default     = null
}

variable "lambda_permissions" {
  description = "Map of Lambda permissions to create (e.g., for API Gateway, EventBridge)"
  type = map(object({
    action     = string
    principal  = string
    source_arn = optional(string)
    qualifier  = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
