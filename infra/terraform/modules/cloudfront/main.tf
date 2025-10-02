resource "aws_cloudfront_distribution" "main" {
  enabled = true
  dynamic "origin" {
    for_each = var.origins

    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      origin_path = origin.value.origin_path

      # Ignored by Terraform if null
      origin_access_control_id = origin.value.origin_access_control_id

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [origin.value.custom_origin_config] : []

        content {
          http_port              = custom_origin_config.value.http_port
          https_port             = custom_origin_config.value.https_port
          origin_protocol_policy = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols   = custom_origin_config.value.origin_ssl_protocols
        }
      }
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.default_cache_behavior.target_origin_id
    compress               = var.default_cache_behavior.compress
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy
    cache_policy_id        = var.default_cache_behavior.cache_policy_id
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.cache_behaviors

    content {
      path_pattern               = ordered_cache_behavior.value.path_pattern
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD"]
      target_origin_id           = ordered_cache_behavior.value.target_origin_id
      compress                   = ordered_cache_behavior.value.compress
      viewer_protocol_policy     = ordered_cache_behavior.value.viewer_protocol_policy
      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.app_security_headers.id
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction.restriction_type
      locations        = var.geo_restriction.locations
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases             = var.aliases
  price_class         = var.price_class
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  web_acl_id          = var.web_acl_id

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  dynamic "logging_config" {
    for_each = var.logging_config != null ? [var.logging_config] : []

    content {
      bucket          = logging_config.value.bucket
      prefix          = logging_config.value.prefix
      include_cookies = logging_config.value.include_cookies
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [var.certificate_arn_validation]

  tags = var.tags
}

resource "aws_cloudfront_response_headers_policy" "app_security_headers" {
  name = "${var.name_prefix}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }

  cors_config {
    access_control_allow_credentials = true

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    }

    access_control_allow_origins {
      items = var.cors_origins
    }

    access_control_max_age_sec = 86400
    origin_override            = true
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_error_rate" {
  alarm_name = "${var.name_prefix}-cloudfront-error-rate"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "CloudFront error rate is above 5% (4xx error rate)"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
    Region         = "Global"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_origin_latency" {
  alarm_name = "${var.name_prefix}-cloudfront-origin-latency"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "OriginLatency"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 3000
  alarm_description   = "CloudFront origin latency is above 3000 ms (high latency)"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
    Region         = "Global"
  }

  tags = var.tags
}
