variable "name_prefix" {
  description = "Prefix for the ECS cluster"
  type        = string
}

variable "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS Task Role"
  type        = string
}

variable "ecr_repository_url_backend" {
  description = "ECR repository URL"
  type        = string
}

variable "ecr_repository_url_frontend" {
  description = "ECR repository URL"
  type        = string
}

variable "environment" {
  description = "Env name of the app"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "rds_secret_arn" {
  description = "ARN of the RDS secret"
  type        = string
}

variable "redis_secret_arn" {
  description = "ARN of the Redis secret"
  type        = string
}

variable "kafka_bootstrap_servers" {
  description = "Bootstrap servers for Kafka"
  type        = string
}

variable "kafka_secret_arn" {
  description = "Kafka secret ARN"
  type        = string
}

variable "mongodb_db_name" {
  description = "Name of the database in the MongoDB Atlas instance"
  type        = string
}

variable "mongodb_db_collection_name" {
  description = "Name of the collection in the MongoDB Atlas instance"
  type        = string
}

variable "mongodb_secret_arn" {
  description = "MongoDB secret ARN"
  type        = string
}

variable "roboflow_model_path" {
  description = "Path to the Roboflow model"
  type        = string
}

variable "roboflow_api_key" {
  description = "API key for Roboflow"
  type        = string
}

variable "smtp_server" {
  description = "SMTP server"
  type        = string
}

variable "smtp_server_port" {
  description = "SMTP server port"
  type        = string
}

variable "smtp_email_app_pass" {
  description = "SMTP email app pass"
  type        = string
}

variable "google_client_id" {
  description = "Google client ID"
  type        = string
}

variable "google_client_secret" {
  description = "Google client secret"
  type        = string
}

variable "facebook_client_id" {
  description = "Facebook client ID"
  type        = string
}

variable "facebook_client_secret" {
  description = "Facebook client secret"
  type        = string
}

variable "apple_client_id" {
  description = "Apple client ID"
  type        = string
}

variable "apple_client_secret" {
  description = "Apple client secret"
  type        = string
}

variable "owner_email" {
  description = "Owner email address"
  type        = string
}

variable "grafana_loki_url" {
  description = "Grafana Loki URL"
  type        = string
}

variable "grafana_loki_username" {
  description = "Grafana Loki username"
  type        = string
}

variable "grafana_loki_password" {
  description = "Grafana Loki password"
  type        = string
}

variable "app_csrf_secret_key" {
  description = "App CSRF secret key"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "ecs_task_execution_role_definition" {
  description = "ECS role policy attachment for task execution"
  type        = list(map(string))
}

variable "nlb_target_group_arn" {
  description = "Target group ARN from the NLB load balancer"
  type        = string
}

variable "nlb_security_group_id" {
  description = "Security group ID from the NLB load balancer"
  type        = string
}

variable "account_id" {
  description = "ID of currently authenticated AWS account"
  type        = string
}

variable "log_retention_days" {
  description = "Days until logs are deleted"
  type        = number
  default     = 7
}

variable "kms_policy" {
  description = "Policy for the KMS key"
  type        = string
}

variable "tags" {
  description = "Tags for the ECS cluster"
  type        = map(string)
}
