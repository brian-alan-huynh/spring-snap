variable "name_prefix" {
  description = "Identification for Cloudflare domain comments"
  type        = string
}

variable "zone_id" {
  description = "The ID of the Cloudflare zone"
  type        = string
}

variable "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  type        = string
}

variable "certificate_arn_dvo" {
  description = "The domain validation options for the ACM certificate"
  type = list(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  }))
}
