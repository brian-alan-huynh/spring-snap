output "s3_bucket_name" {
  description = "Name of the S3 bucket that holds Terraform state and lock files"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket that holds Terraform state and lock files"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_region" {
  description = "AWS region where the S3 bucket that holds Terraform state and lock files is stored"
  value       = aws_s3_bucket.terraform_state.region
}

output "backend_config" {
  description = "Terraform backend config block for the main/core infrastructure w/ S3 native state locking"
  value       = <<EOF
        terraform {
            backend "s3" {
                bucket = "${aws_s3_bucket.terraform_state.bucket}"
                key = "terraform.tfstate"
                region = "${var.aws_region}"
                encrypt = true
                use_lockfile = true
            }
        }
    EOF
}
