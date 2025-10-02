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

variable "docker_registry" {
  description = "Docker registry URL (i.e, Docker Hub, ECR, etc)"
  type        = string
  default     = "docker.io"
}

variable "backend_image_name" {
  description = "Name of the backend Docker image"
  type        = string
  default     = "springsnap/backend"
}

variable "frontend_image_name" {
  description = "Name of the frontend Docker image"
  type        = string
  default     = "springsnap/frontend"
}

variable "image_tag" {
  description = "Tag of the image"
  type        = string
  default     = "latest"
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "rds_username" {
  description = "Username of the RDS instance"
  type        = string
}

variable "rds_db_host" {
  description = "Host of the database in the RDS instance"
  type        = string
}

variable "rds_db_name" {
  description = "Name of the database in the RDS instance"
  type        = string
}

variable "rds_db_port" {
  description = "Port of the database in the RDS instance"
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

variable "mongodb_secret_arn" {
  description = "MongoDB secret ARN"
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
