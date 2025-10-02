resource "aws_api_gatewayv2_api" "main" {
  name          = "${var.name_prefix}-api"
  protocol_type = "HTTP"
  description   = "API Gateway for Springsnap"

  cors_configuration {
    allow_credentials = false
    allow_headers     = var.cors_headers
    allow_methods     = var.cors_methods
    allow_origins     = var.cors_origins
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_api_gatewayv2_api.main.api_id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.destination_arn

    format = jsonencode({
      requestID      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error = {
        message       = "$context.error.message"
        messageString = "$context.error.messageString"
      }
      integration = {
        error             = "$context.integration.error"
        integrationStatus = "$context.integration.integrationStatus"
        latency           = "$context.integration.latency"
        requestId         = "$context.integration.requestId"
        status            = "$context.integration.status"
      }
    })
  }

  default_route_settings {
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
  }

  depends_on = [aws_cloudwatch_log_group.api_gw]

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "nlb" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "HTTP_PROXY"

  integration_method = "ANY"
  integration_uri    = var.nlb_uri

  connection_type = "VPC_LINK"
  connection_id   = var.vpc_link_id

  timeout_milliseconds = 28000

  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /"

  target = "integrations/${aws_apigatewayv2_integration.nlb.id}"
}

resource "aws_apigatewayv2_route" "csrf" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /csrf"

  target = "integrations/${aws_apigatewayv2_integration.csrf.id}"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"

  target = "integrations/${aws_apigatewayv2_integration.nlb.id}"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /api/v1/{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.nlb.id}"
}

resource "aws_apigatewayv2_domain_name" "main" {
  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [var.certificate_arn_validation]

  tags = var.tags
}

resource "aws_apigatewayv2_api_mapping" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  domain_name = aws_apigatewayv2_domain_name.main.id
  stage       = aws_apigatewayv2_stage.prod.id
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_apigatewayv2_stage.prod.arn
  web_acl_arn  = var.web_acl_arn
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.name_prefix}"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_4xx_errors" {
  alarm_name          = "${var.name_prefix}-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Monitors 4XX errors that are being returned from the API Gateway."

  dimensions = {
    ApiName = aws_apigatewayv2_api.main.name
    Stage   = aws_apigatewayv2_stage.prod.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${var.name_prefix}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Monitors 5XX errors that are being returned from the API Gateway."

  dimensions = {
    ApiName = aws_apigatewayv2_api.main.name
    Stage   = aws_apigatewayv2_stage.prod.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.name_prefix}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"
  alarm_description   = "High latency detected in API Gateway."

  dimensions = {
    ApiName = aws_apigatewayv2_api.main.name
    Stage   = aws_apigatewayv2_stage.prod.name
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl" "api_protection" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.name_prefix}-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-web-acl"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_association" "api_gateway" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_apigatewayv2_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.api_protection.arn
}
