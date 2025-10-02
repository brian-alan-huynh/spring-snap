variable "name_prefix" {
  description = "Prefix for the S3 bucket naming"
  type        = string
}

# Uncomment for prod
# variable "cloudfront_distribution_arn" {
#     description = "CloudFront distribution ARN"
#     type = string
# }

variable "frontend_domain_name" {
  description = "Frontend domain name"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
}
