# Main S3 bucket
output "main_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "main_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "main_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "main_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "main_bucket_oac" {
  description = "OAC for S3 bucket origin to use in CloudFront distribution"
  value       = aws_cloudfront_origin_access_control.main.id
}

# CloudFront logs S3 bucket
# Uncomment for prod
# output "cloudfront_logs_bucket_name" {
#   description = "Name of the S3 bucket for CloudFront logs"
#   value       = aws_s3_bucket.cloudfront_logs.id
# }

# output "cloudfront_logs_bucket_arn" {
#   description = "ARN of the S3 bucket for CloudFront logs"
#   value       = aws_s3_bucket.cloudfront_logs.arn
# }

# output "cloudfront_logs_bucket_domain_name" {
#   description = "Domain name of the S3 bucket for CloudFront logs"
#   value       = aws_s3_bucket.cloudfront_logs.bucket_domain_name
# }

# output "cloudfront_logs_bucket_regional_domain_name" {
#   description = "Regional domain name of the S3 bucket for CloudFront logs"
#   value       = aws_s3_bucket.cloudfront_logs.bucket_regional_domain_name
# }
