variable "name_prefix" {
  description = "Prefix for the RDS instance"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the RDS instance"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs for the RDS instance"
  type        = list(string)
}

variable "local_cidr_block" {
  description = "Local machine IP address with subnet mask"
  type        = string
}

variable "environment" {
  description = "Environment for the RDS instance"
  type        = string
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
}

variable "db_username" {
  description = "Username for user in the RDS database"
  type        = string
}

variable "db_app_username" {
  description = "Username for app user in the RDS database"
  type        = string
}

variable "kms_policy" {
  description = "Policy for the KMS key"
  type        = string
}

variable "tags" {
  description = "Tags for the RDS instance"
  type        = map(string)
}
