variable "name_prefix" {
  description = "Prefix for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "kms_policy" {
  description = "KMS policy for the VPC (generated via data {...} block)"
  type        = string
}

variable "tags" {
  description = "Tags for the VPC"
  type        = map(string)
}
