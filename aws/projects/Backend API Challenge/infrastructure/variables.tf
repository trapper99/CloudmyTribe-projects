variable "s3_bucket_name" {
  type        = "string"
  description = "S3 bucket name"
  default     = "cloud-resume-bucket"
}

variable "dynamodb_table_name" {
  type        = "string"
  description = "DynamoDB table name"
  default     = "resume-table"
}

variable "aws_account_id" {
    type        = "string"
    description = "AWS account ID"
    default     = "478056848832"
 }

variable "aws_region" {
  type        = "string"
  description = "AWS region"
  default     = "us-west-2"
}

variable "lambda_function_name" {
  type        = "string"
  description = "Lambda function name"
  default     = "resume-builder"
}

variable "api_gateway_name" {
  type        = "string"
  default     = "resume-builder"
}
