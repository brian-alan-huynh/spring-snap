variable "aws_region" {
  description = "AWS region where the S3 bucket that holds Terraform state and lock files will be stored"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (dev or prod) used for tagging/naming S3 resources"
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^(dev|prod)$", var.environment))
    error_message = "Environment must be either 'dev' or 'prod'"
  }
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket that will hold Terraform state and lock files"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-][a-z0-9-]*[a-z0-9]$", var.state_bucket_name)) && length(var.state_bucket_name) >= 3 && length(var.state_bucket_name) <= 63
    error_message = "S3 state bucket name must be between 3 and 63 characters long, lowercase, start with a letter or number, and contain only letters, numbers, and hyphens"
  }
}

variable "project_name" {
  description = "Name of the project (used for resource tagging)"
  type        = string
  default     = "Springsnap"
}
