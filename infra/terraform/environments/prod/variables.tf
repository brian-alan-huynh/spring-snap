# Project
variable "project_name" {
  description = "Name of project (used as prefix for all resources)"
  type        = string
  default     = "springsnap"
}

variable "environment" {
  description = "Env name (dev or prod)"
  type        = string
  default     = "prod"
}

variable "owner_email" {
  description = "Email address of the infra owner (used for tagging and notifications)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner_email))
    error_message = "Owner email must be a valid email address"
  }
}

variable "frontend_domain_name" {
  description = "Frontend domain name"
  type        = string
  default     = "https://springsnap.org"

  validation {
    condition     = can(regex("^https?://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.frontend_domain_name))
    error_message = "Frontend domain must be a valid URL"
  }
}

variable "api_domain_name" {
  description = "API domain name"
  type        = string
  default     = "api.springsnap.org"

  validation {
    condition     = can(regex("^https?://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.api_domain_name))
    error_message = "API domain must be a valid URL"
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

# EC2
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum instances in ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum instances in ASG"
  type        = number
  default     = 8
}

variable "asg_desired_capacity" {
  description = "Desired instances in ASG"
  type        = number
  default     = 2
}

variable "docker_image" {
  description = "Docker image name"
  type        = string
}

variable "docker_registry_username" {
  description = "Docker Hub username"
  type        = string
  sensitive   = true
}

variable "docker_registry_password" {
  description = "Docker Hub password"
  type        = string
  sensitive   = true
}

# RDS
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_app_username" {
  description = "Database application username"
  type        = string
}

# API Gateway
variable "api_throttle_burst_limit" {
  description = "API Gateway burst limit"
  type        = number
  default     = 500
}

variable "api_throttle_rate_limit" {
  description = "API Gateway rate limit"
  type        = number
  default     = 250
}

# WAF
variable "waf_rate_limit" {
  description = "Rate limit for WAF per IP per 5 minutes"
  type        = number
  default     = 2000
}

# Cloudfront
variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_200"
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
}

variable "mongodbatlas_db_password" {
  description = "MongoDB Atlas database password"
  type        = string
  sensitive   = true
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
