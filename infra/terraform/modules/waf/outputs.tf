output "cloudfront_waf_web_acl_arn" {
  description = "The ARN of the CloudFront WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "regional_waf_web_acl_arn" {
  description = "The ARN of the Regional WAF Web ACL"
  value       = aws_wafv2_web_acl.regional.arn
}
