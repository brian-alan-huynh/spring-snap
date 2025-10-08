# Project
variable "project_name" {
  description = "Name of project (used as prefix for all resources)"
  type        = string
  default     = "springsnap"
}

variable "environment" {
  description = "Env name (dev or prod)"
  type        = string
  default     = "dev"
}

variable "owner_email" {
  description = "Email address of the infra owner (used for tagging and notifications)"
  type        = string
  sensitive   = true
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

# RDS
variable "rds_db_instance_class" {
  description = "Instance class for RDS"
  type        = string
}

variable "rds_db_name" {
  description = "Database name for RDS"
  type        = string
}

variable "rds_db_username" {
  description = "Database username for RDS"
  type        = string
  sensitive   = true
}

variable "rds_db_app_username" {
  description = "Database application username for RDS"
  type        = string
  sensitive   = true
}

# Grafana
variable "grafana_cloud_external_id" {
  description = "Grafana Cloud external ID taken from Grafana Cloud UI dashboard"
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
  description = "Confluent Cloud API key"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API secret"
  type        = string
  sensitive   = true
}
