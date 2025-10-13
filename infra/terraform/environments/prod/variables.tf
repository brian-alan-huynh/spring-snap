# Project
variable "project_name" {
  description = "Name of project (used as prefix for all resources)"
  type        = string
  default     = "curby"
}

variable "environment" {
  description = "Env name (dev or prod)"
  type        = string
  default     = "prod"
}

variable "owner_email" {
  description = "Email address of the infra owner (used for tagging and notifications)"
  type        = string
}

variable "frontend_domain_name" {
  description = "Frontend domain name"
  type        = string
  default     = "https://curbystorage.com"
}

variable "api_domain_name" {
  description = "API domain name"
  type        = string
  default     = "api.curbystorage.com"
}

# VPC

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

# EC2
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

# RDS
variable "rds_db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_db_name" {
  description = "Database name"
  type        = string
}

variable "rds_db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "rds_db_app_username" {
  description = "Database application username"
  type        = string
  sensitive   = true
}

# Grafana
variable "grafana_cloud_external_id" {
  description = "Grafana Cloud external ID taken from Grafana Cloud UI dashboard"
  type        = string
  sensitive   = true
}

# Cloudflare
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

# MongoDB Atlas
variable "mongodbatlas_public_key" {
  description = "MongoDB Atlas public key"
  type        = string
  sensitive   = true
}

variable "mongodbatlas_private_key" {
  description = "MongoDB Atlas private key"
  type        = string
  sensitive   = true
}

variable "mongodbatlas_org_id" {
  description = "MongoDB Atlas organization ID"
  type        = string
  sensitive   = true
}

variable "mongodbatlas_db_password" {
  description = "MongoDB Atlas database password"
  type        = string
  sensitive   = true
}

variable "mongodb_db_name" {
  description = "MongoDB Atlas database name"
  type        = string
}

# Confluent Kafka
variable "confluent_cloud_api_key" {
  description = "API key for Confluent Kafka Cloud"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "API secret for Confluent Kafka Cloud"
  type        = string
  sensitive   = true
}

# Backend app .env variables (values passed via run_export_env_vars_to_tf.sh)
variable "google_client_id" {
  description = "Google client ID"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google client secret"
  type        = string
  sensitive   = true
}

variable "facebook_client_id" {
  description = "Facebook client ID"
  type        = string
  sensitive   = true
}

variable "facebook_client_secret" {
  description = "Facebook client secret"
  type        = string
  sensitive   = true
}

variable "apple_client_id" {
  description = "Apple client ID"
  type        = string
  sensitive   = true
}

variable "apple_client_secret" {
  description = "Apple client secret"
  type        = string
  sensitive   = true
}

variable "mongodb_db_collection_name" {
  description = "MongoDB Atlas database collection name"
  type        = string
}

variable "roboflow_model_path" {
  description = "Roboflow model path"
  type        = string
}

variable "roboflow_api_key" {
  description = "Roboflow API key"
  type        = string
  sensitive   = true
}

variable "smtp_server" {
  description = "SMTP server"
  type        = string
}

variable "smtp_server_port" {
  description = "SMTP server port"
  type        = number
}

variable "smtp_email_app_pass" {
  description = "SMTP email app pass"
  type        = string
  sensitive   = true
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
  sensitive   = true
}

variable "app_csrf_secret_key" {
  description = "App CSRF secret key"
  type        = string
  sensitive   = true
}
