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

variable "rds_secret_arn" {
  description = "RDS secret ARN"
  type        = string
  sensitive   = true
}

variable "redis_secret_arn" {
  description = "Redis secret ARN"
  type        = string
  sensitive   = true
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

variable "google_client_id_secret_arn" {
  description = "Google client ID secret ARN"
  type        = string
  sensitive   = true
}

variable "google_client_secret_secret_arn" {
  description = "Google client secret secret ARN"
  type        = string
  sensitive   = true
}

variable "owner_email_secret_arn" {
  description = "Owner email secret ARN"
  type        = string
  sensitive   = true
}

variable "roboflow_api_key_secret_arn" {
  description = "Roboflow API key secret ARN"
  type        = string
  sensitive   = true
}

variable "smtp_email_app_pass_secret_arn" {
  description = "SMTP email app pass secret ARN"
  type        = string
  sensitive   = true
}

variable "grafana_loki_url_secret_arn" {
  description = "Grafana Loki URL secret ARN"
  type        = string
  sensitive   = true
}

variable "grafana_loki_username_secret_arn" {
  description = "Grafana Loki username secret ARN"
  type        = string
  sensitive   = true
}

variable "grafana_loki_password_secret_arn" {
  description = "Grafana Loki password secret ARN"
  type        = string
  sensitive   = true
}

variable "app_csrf_secret_key_secret_arn" {
  description = "App CSRF secret key secret ARN"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags for the IAM resources"
  type        = map(string)
}
