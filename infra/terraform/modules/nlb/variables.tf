variable "name_prefix" {
  description = "The name prefix for the NLB"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets in which the NLB will be created"
  type        = list(string)
}

variable "access_logs_bucket" {
  description = "The name of the S3 bucket where the access logs will be stored"
  type        = string
}

variable "target_port" {
  description = "The port on which the target is listening"
  type        = number
  default     = 8000
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "target_protocol" {
  description = "The protocol on which the target is listening"
  type        = string
  default     = "HTTP"
}

variable "vpc_id" {
  description = "The ID of the VPC in which the NLB will be created"
  type        = string
}

variable "tags" {
  description = "The tags to be applied to the NLB and target group"
  type        = map(string)
}
