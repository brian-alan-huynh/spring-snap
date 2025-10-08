# Main S3 bucket
resource "aws_s3_bucket" "main" {
  bucket = "${var.name_prefix}-snaps"

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "main" {
  count = var.environment == "dev" ? 0 : 1

  bucket = aws_s3_bucket.main.id

  policy = jsondecode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "intelligent_tiering_transition"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "old_versions_cleanup"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 15
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  name = "${var.name_prefix}-intelligent-tiering"

  filter {
    prefix = ""
  }
  tiering {
    days        = 90
    access_tier = "ARCHIVE_ACCESS"
  }

  tiering {
    days        = 180
    access_tier = "DEEP_ARCHIVE_ACCESS"
  }

  status = "Enabled"
}

resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["Content-Type", "Authorization"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = [var.frontend_domain_name]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_metric" "main" {
  bucket = aws_s3_bucket.main.id

  name = "${var.name_prefix}-metrics"

  filter {
    prefix = ""
  }
}

resource "aws_cloudfront_origin_access_control" "main" {
  count = var.environment == "dev" ? 0 : 1

  name                              = "${var.name_prefix}-s3-oac"
  description                       = "OAC for main S3 bucket origin to use in CloudFront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Logging S3 bucket
resource "aws_s3_bucket" "logging" {
  count = var.environment == "dev" ? 0 : 1

  bucket = "${var.name_prefix}-logging"

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "logging" {
  count = var.environment == "dev" ? 0 : 1

  bucket = aws_s3_bucket.logging.id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  count = var.environment == "dev" ? 0 : 1

  bucket = aws_s3_bucket.logging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logging" {
  count = var.environment == "dev" ? 0 : 1

  bucket = aws_s3_bucket.logging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logging" {
  count = var.environment == "dev" ? 0 : 1

  bucket = aws_s3_bucket.logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAndNLBAccess"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logging.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          }
          ArnLike = {
            "aws:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      },
      {
        Sid    = "AllowNLBLogDeliveryAclCheckAccess"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logging.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.logging]
}

resource "aws_s3_bucket_ownership_controls" "logging" {
  count = var.environment == "dev" ? 0 : 1

  bucket = aws_s3_bucket.logging.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  count = var.environment == "dev" ? 0 : 1

  bucket = aws_s3_bucket.logging.id

  rule {
    id     = "log_retention"
    status = "Enabled"

    transition {
      days          = 15
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    transition {
      days          = 60
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 90
    }
  }
}

# Main S3 bucket reports to logging S3 bucket
resource "aws_s3_bucket_inventory" "main" {
  count = var.environment == "dev" ? 0 : 1

  bucket = aws_s3_bucket.main.id
  name   = "${var.name_prefix}-inventory"

  destination {
    bucket {
      bucket_arn = aws_s3_bucket.logging.arn
      prefix     = "inventory/"
      format     = "CSV"
    }
  }

  included_object_versions = "Current"

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus"
  ]

  schedule {
    frequency = "Daily"
  }

  enabled = true
}
