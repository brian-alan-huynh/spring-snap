variable "name_prefix" {
  description = "Prefix for the CloudFront distribution"
  type        = string
}

variable "origins" {
  description = "List of origins for the CloudFront distribution"
  type = list(object({
    domain_name              = string
    origin_id                = string
    origin_path              = string
    origin_access_control_id = optional(string)
    custom_origin_config = optional(object({
      http_port              = number
      https_port             = number
      origin_protocol_policy = string
      origin_ssl_protocols   = list(string)
    }))
  }))
}

variable "default_cache_behavior" {
  description = "Default cache behavior configuration"
  type = object({
    target_origin_id         = string
    compress                 = bool
    viewer_protocol_policy   = string
    cache_policy_id          = string
    origin_request_policy_id = optional(string)
  })
}

variable "cache_behaviors" {
  description = "List of cache behaviors for different path patterns"
  type = list(object({
    path_pattern             = string
    target_origin_id         = string
    compress                 = bool
    viewer_protocol_policy   = string
    cache_policy_id          = string
    origin_request_policy_id = optional(string)
  }))
}

variable "aliases" {
  description = "List of custom domain names"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domains"
  type        = string
}

variable "certificate_arn_validation" {
  description = "ACM certificate ARN validation"
  type        = list(map(string))
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "geo_restriction" {
  description = "Geographic restriction configuration"
  type = object({
    restriction_type = string
    locations        = list(string)
  })
}

variable "logging_config" {
  description = "Access logging configuration"
  type = object({
    bucket          = string
    prefix          = string
    include_cookies = bool
  })
  default = null
}

variable "web_acl_id" {
  description = "WAF Web ACL ID"
  type        = string
}

variable "cors_origins" {
  description = "CORS allowed origins"
  type        = list(string)
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
}
