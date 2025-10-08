# Main S3 bucket
output "main_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket
}

output "main_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "main_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "main_bucket_oac" {
  description = "OAC for S3 bucket origin to use in CloudFront distribution"
  value       = length(aws_cloudfront_origin_access_control.main) > 0 ? aws_cloudfront_origin_access_control.main[0].id : null
}

# Logging S3 bucket
output "logging_bucket_name" {
  description = "Name of the S3 bucket for CloudFront logs"
  value       = length(aws_s3_bucket.logging) > 0 ? aws_s3_bucket.logging[0].bucket : null
}
