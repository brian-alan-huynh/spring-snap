output "s3_bucket_name" {
  description = "Name of the S3 bucket that holds Terraform state and lock files"
  value       = { for bucket_key, bucket in aws_s3_bucket.state : bucket_key => bucket.id }
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket that holds Terraform state and lock files"
  value       = { for bucket_key, bucket in aws_s3_bucket.state : bucket_key => bucket.arn }
}

output "s3_bucket_region" {
  description = "AWS region where the S3 bucket that holds Terraform state and lock files is stored"
  value       = { for bucket_key, bucket in aws_s3_bucket.state : bucket_key => bucket.region }
}
