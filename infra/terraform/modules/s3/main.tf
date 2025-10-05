resource "aws_s3_bucket" "main" {
  bucket = "${var.name_prefix}-snaps"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-snaps"
    Purpose     = "Storage for user image snaps"
    Environment = lookup(var.tags, "Environment", "Unknown")
  })
}

# Uncomment for prod
# resource "aws_s3_bucket" "cloudfront_logs"  {
#     bucket = "${var.name_prefix}-cloudfront-logs"

#     tags = merge(var.tags, {
#         Name = "${var.name_prefix}-cloudfront-logs"
#         Purpose = "CloudFront logs storage"
#         Environment = lookup(var.tags, "Environment", "Unknown")
#     })
# }

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

# Uncomment for prod
# resource "aws_s3_bucket_policy" "main" {
#     bucket = aws_s3_bucket.main.id

#     policy = jsondecode({
#         Version = "2012-10-17"
#         Statement = [
#             {
#                 Sid = "AllowCloudFrontAccess"
#                 Effect = "Allow"
#                 Principal = {
#                     Service = "cloudfront.amazonaws.com"
#                 }
#                 Condition = {
#                     StringEquals = {
#                         "AWS:SourceArn" = var.cloudfront_distribution_arn
#                     }
#                 }
#                 Action = "s3:GetObject"
#                 Resource = "${aws_s3_bucket.main.arn}/*"
#             }
#         ]
#     })

#     depends_on = [ aws_s3_bucket_public_access_block.main ]
# }

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

# Uncomment for prod
# resource "aws_s3_bucket_versioning" "cloudfront_logs" {
#     bucket = aws_s3_bucket.cloudfront_logs.id

#     versioning_configuration {
#       status = "Suspended"
#     }
# }

# resource "aws_s3_bucket_policy" "cloudfront_logs" {
#     bucket = aws_s3_bucket.cloudfront_logs.id

#     policy = jsonencode({
#         Version = "2012-10-17"
#         Statement = [
#             {
#                 Sid = "AllowCloudFrontAccess"
#                 Effect = "Allow"
#                 Principal = {
#                     Service = "cloudfront.amazonaws.com"
#                 }
#                 Condition = {
#                     StringEquals = {
#                         "AWS:SourceArn" = var.cloudfront_distribution_arn
#                     }
#                 }
#                 Action = "s3:PutObject"
#                 Resource = "${aws_s3_bucket.cloudfront_logs.arn}/*"
#             }
#         ]
#     })
# }

# resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
#     bucket = aws_s3_bucket.cloudfront_logs.id

#     rule {
#         object_ownership = "BucketOwnerEnforced"
#     }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
#     bucket = aws_s3_bucket.cloudfront_logs.id

#     rule {
#         id = "log_retention"
#         status = "Enabled"

#         transition {
#           days = 15
#           storage_class = "STANDARD_IA"
#         }

#         transition {
#           days = 30
#           storage_class = "GLACIER"
#         }

#         transition {
#           days = 60
#           storage_class = "DEEP_ARCHIVE"
#         }

#         expiration {
#           days = 90
#         }
#     }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
#     bucket = aws_s3_bucket.cloudfront_logs.id

#     rule {
#         apply_server_side_encryption_by_default {
#             sse_algorithm = "AES256"
#         }

#         bucket_key_enabled = true
#     }
# }

# resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
#     bucket = aws_s3_bucket.cloudfront_logs.id

#     block_public_acls = true
#     block_public_policy = true
#     ignore_public_acls = true
#     restrict_public_buckets = true
# }

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

# Uncomment for prod
# resource "aws_s3_bucket_inventory" "main" {
#     bucket = aws_s3_bucket.main.id
#     name = "${var.name_prefix}-inventory"

#     destination {
#       bucket {
#         bucket_arn = aws_s3_bucket.cloudfront_logs.ARN
#         prefix = "inventory/"
#         format = "CSV"
#       }
#     }

#     included_object_versions = "Current"

#     optional_fields = [
#         "Size",
#         "LastModifiedDate",
#         "StorageClass",
#         "ETag",
#         "IsMultipartUploaded",
#         "ReplicationStatus"
#     ]

#     schedule {
#         frequency = "Daily"
#     }

#     enabled = true
# }

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.name_prefix}-s3-oac"
  description                       = "OAC for S3 bucket origin to use in CloudFront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
