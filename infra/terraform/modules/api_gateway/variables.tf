variable "name_prefix" {
  description = "Prefix for the API Gateway resources"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.tags) == 0 || (contains(keys(var.tags), "Environment") && contains(keys(var.tags), "Project"))
    error_message = "Tags must contain Environment and Project keys"
  }
}

variable "custom_domain_name" {
  description = "Custom domain name for the API Gateway"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the certificate for the custom domain"
  type        = string
}

variable "certificate_arn_validation" {
  description = "ARN of the certificate validation for the custom domain"
  type        = string
}

variable "vpc_link_id" {
  description = "ID of the VPC link for the API Gateway"
  type        = string
}

variable "nlb_uri" {
  description = "NLB URI for integration"
  type        = string
}

variable "cors_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]

  validation {
    condition     = length(var.cors_origins) > 0
    error_message = "CORS origins must be specified"
  }
}

variable "cors_headers" {
  description = "CORS allowed headers"
  type        = list(string)
  default     = ["content-type", "x-amz-date", "authorization", "x-api-key"]

  validation {
    condition     = length(var.cors_headers) > 0
    error_message = "CORS headers must be specified"
  }
}

variable "cors_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["*"]

  validation {
    condition     = length(var.cors_methods) > 0
    error_message = "CORS methods must be specified"
  }
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
}

variable "enable_waf" {
  description = "Enable WAF protection"
  type        = bool
}

variable "web_acl_arn" {
  description = "ARN of the WAF web ACL"
  type        = string
}

variable "waf_rate_limit" {
  description = "WAF rate limit per IP per 5 minutes"
  type        = number
}
