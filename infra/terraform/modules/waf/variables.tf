variable "name_prefix" {
  description = "Name prefix for the WAF Web ACL"
  type        = string
}

variable "cloudfront_web_acl_name" {
  description = "Name for the CloudFront WAF Web ACL"
  type        = string
}

variable "regional_web_acl_name" {
  description = "Name for the Regional WAF Web ACL"
  type        = string
}

variable "tags" {
  description = "Tags for the WAF Web ACL"
  type        = map(string)
}
