terraform {
    required_version = ">= 1.5"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = var.aws_region

    default_tags {
        tags = {
            Project = var.project_name
            Environment = var.environment
            ManagedBy = "Terraform"
            Purpose = "TerraformState"
        }
    }
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = var.state_bucket_name

    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_ssec" {
    bucket = aws_s3_bucket.terraform_state.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }

        bucket_key_enabled = true
    }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_pab" {
    bucket = aws_s3_bucket.terraform_state.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}
