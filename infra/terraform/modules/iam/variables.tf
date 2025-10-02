variable "name_prefix" {
  description = "Prefix for the IAM resources naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "rds_db_username" {
  description = "DB username"
  type        = string
}

variable "rds_resource_id" {
  description = "RDS resource ID"
  type        = string
}

variable "kafka_secret_arn" {
  description = "Kafka secret ARN"
  type        = string
  sensitive   = true
}

variable "mongodb_secret_arn" {
  description = "MongoDB secret ARN"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags for the IAM resources"
  type        = map(string)
}
