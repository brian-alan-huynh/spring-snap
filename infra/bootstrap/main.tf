terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "TerraformState"
      Owner = var.owner_email
    }
  }
}

resource "aws_s3_bucket" "state" {
  for_each = var.state_bucket_names

  bucket = each.value

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  for_each = var.state_bucket_names

  bucket = aws_s3_bucket.state[each.value].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_ssec" {
  for_each = var.state_bucket_names

  bucket = aws_s3_bucket.state[each.value].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state_pab" {
  for_each = var.state_bucket_names

  bucket = aws_s3_bucket.state[each.value].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
