# Project
variable "project_name" {
  description = "Name of project (used as prefix for all resources)"
  type        = string
  default     = "springsnap"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, can only contain letters, numbers, and hyphens, and must end with a letter or number"
  }
}

variable "environment" {
  description = "Env name (dev or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'"
  }
}

variable "owner_email" {
  description = "Email address of the infra owner (used for tagging and notifications)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the resources will be deployed"
  type        = string
  default     = "us-east-2"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.aws_region))
    error_message = "AWS region must be a valid AWS region"
  }
}

variable "frontend_domain_name" {
  description = "Frontend domain name"
  type        = string
  default     = "http://localhost:3000"

  validation {
    condition     = can(regex("^https?://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.frontend_domain_name))
    error_message = "Frontend domain name must be a valid URL"
  }
}

# VPC
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Availability zones must be a list of 3 zones"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block"
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 3
    error_message = "Public subnet CIDRs must be a list of 3 CIDR blocks"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 3
    error_message = "Private subnet CIDRs must be a list of 3 CIDR blocks"
  }
}

# RDS
variable "db_engine_version" {
  description = "Engine version for RDS"
  type        = string
  default     = "15.4"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.db_engine_version))
    error_message = "RDS engine version must be a valid version number"
  }
}

variable "db_instance_class" {
  description = "Instance class for RDS"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.db_instance_class))
    error_message = "RDS instance class must be a valid instance class"
  }
}

variable "db_name" {
  description = "Database name for RDS"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.db_name))
    error_message = "RDS database name must be a valid database name"
  }
}

variable "db_username" {
  description = "Database username for RDS"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.db_username))
    error_message = "RDS database username must be a valid database username"
  }
}

variable "db_app_username" {
  description = "Database application username for RDS"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.db_app_username))
    error_message = "RDS database application username must be a valid database username"
  }
}

variable "db_backup_retention_period" {
  description = "Days to retain RDS backups"
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_period >= 7 && var.db_backup_retention_period <= 35
    error_message = "RDS database backup retention period must be between 7 and 35 days"
  }

}

# MongoDB Atlas
variable "mongodbatlas_public_key" {
  description = "MongoDB Atlas public key"
  type        = string
}

variable "mongodbatlas_private_key" {
  description = "MongoDB Atlas private key"
  type        = string
}

variable "mongodbatlas_org_id" {
  description = "MongoDB Atlas organization ID"
  type        = string
}

variable "mongodbatlas_db_password" {
  description = "MongoDB Atlas database password"
  type        = string
  sensitive   = true
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
