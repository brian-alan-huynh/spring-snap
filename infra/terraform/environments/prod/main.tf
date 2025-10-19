terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.15.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0.0"
    }
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "~> 2.4.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.0.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.4.0"
    }
  }

  backend "s3" {
    bucket       = "curby-state-prod"
    key          = "prod/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "TerraformInfrastructure"
      Owner       = var.owner_email
      CostCenter  = "engineering"
      Compliance  = "required"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "TerraformInfrastructure"
      Owner       = var.owner_email
      CostCenter  = "engineering"
      Compliance  = "required"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "rediscloud" {}

provider "mongodbatlas" {
  public_key  = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "http" "local_public_ip" {
  url = "https://ifconfig.me/ip"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "EnableRootAndAdminaccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.account_id}:root",
        data.aws_caller_identity.current.arn
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCryptographicUsage"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [module.iam.ecs_task_role_arn]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.region}:${local.account_id}:*"]
    }
  }

  statement {
    sid    = "AllowIAMDelegation"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

data "cloudflare_zone" "curby_org" {
  name = "curbystorage.com"
}

data "rediscloud_payment_method" "visa" {
  card_type = "Visa"
}

data "rediscloud_essentials_plan" "free" {
  size                  = 30
  size_measurement_unit = "MB"
  cloud_provider        = "AWS"
  region                = "us-east-2"
  availability          = "No replication"
  support_replication   = false
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
  kms_policy  = data.aws_iam_policy_document.kms.json

  common_tags = {
    Environment        = var.environment
    Project            = var.project_name
    ManagedBy          = "Terraform"
    Purpose            = "TerraformInfrastructure"
    Owner              = var.owner_email
    CostCenter         = "engineering"
    Compliance         = "required"
    DataClassification = "confidential"
    BackupRequired     = "yes"
    MonitoringRequired = "yes"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix = local.name_prefix

  vpc_cidr           = var.vpc_cidr_block
  availability_zones = data.aws_availability_zones.available.names

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  region     = local.region
  kms_policy = local.kms_policy

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix = local.name_prefix

  db_instance_class = var.rds_db_instance_class
  db_name           = var.rds_db_name
  db_username       = var.rds_db_username
  db_app_username   = var.rds_db_app_username

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.ec2.ec2_security_group_id]
  local_cidr_block           = "${chomp(data.http.local_public_ip.response_body)}/32"

  environment = var.environment
  kms_policy  = local.kms_policy

  tags = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  name_prefix = local.name_prefix

  environment                 = var.environment
  account_id                  = local.account_id
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  frontend_domain_name        = var.frontend_domain_name

  tags = local.common_tags
}

module "ec2" {
  source = "../../modules/ec2"

  name_prefix = local.name_prefix

  instance_type = var.ec2_instance_type
  ami_id        = data.aws_ami.amazon_linux_2.id
  key_name      = var.ec2_key_name

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  vpc_cidr   = module.vpc.vpc_cidr_block

  target_group_arns = [module.nlb.target_group_arn]

  iam_instance_profile_name = module.iam.ec2_instance_profile_name

  user_data = templatefile("../../modules/ec2/user_data.sh", {
    ecs_cluster_name = module.ecs.cluster_name
    cw_namespace     = local.name_prefix
  })

  tags = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix = local.name_prefix

  asg_arn = module.ec2.asg_arn

  ecs_task_execution_role_arn        = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn                  = module.iam.ecs_task_role_arn
  ecs_task_execution_role_definition = module.iam.ecs_task_execution_role_definition

  ecr_repository_url_backend  = module.ecr.repository_url_backend
  ecr_repository_url_frontend = module.ecr.repository_url_frontend

  environment                = var.environment
  frontend_domain_name       = var.frontend_domain_name
  s3_bucket_name             = module.s3.main_bucket_name
  kafka_bootstrap_servers    = module.confluent_kafka.bootstrap_servers
  mongodb_db_name            = var.mongodb_db_name
  mongodb_db_collection_name = var.mongodb_db_collection_name
  roboflow_model_path        = var.roboflow_model_path
  smtp_server                = var.smtp_server
  smtp_server_port           = var.smtp_server_port

  rds_secret_arn         = module.rds.secret_arn
  redis_secret_arn       = module.redis.secret_arn
  kafka_secret_arn       = module.confluent_kafka.secret_arn
  mongodb_secret_arn     = module.mongodb.secret_arn
  google_client_id       = var.google_client_id
  google_client_secret   = var.google_client_secret
  facebook_client_id     = var.facebook_client_id
  facebook_client_secret = var.facebook_client_secret
  apple_client_id        = var.apple_client_id
  apple_client_secret    = var.apple_client_secret
  owner_email            = var.owner_email
  roboflow_api_key       = var.roboflow_api_key
  smtp_email_app_pass    = var.smtp_email_app_pass
  grafana_loki_url       = var.grafana_loki_url
  grafana_loki_username  = var.grafana_loki_username
  grafana_loki_password  = var.grafana_loki_password
  app_csrf_secret_key    = var.app_csrf_secret_key

  region     = local.region
  account_id = local.account_id

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  nlb_target_group_arn  = module.nlb.target_group_arn
  nlb_security_group_id = module.nlb.security_group_id

  kms_policy = local.kms_policy

  tags = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = local.name_prefix

  kms_policy = local.kms_policy

  tags = local.common_tags
}

module "nlb" {
  source = "../../modules/nlb"

  name_prefix = local.name_prefix

  vpc_id     = module.vpc.vpc_id
  vpc_cidr   = module.vpc.vpc_cidr_block
  subnet_ids = module.vpc.private_subnet_ids

  s3_logging_bucket_name = module.s3.logging_bucket_name

  tags = local.common_tags
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  name_prefix = local.name_prefix

  custom_domain_name = var.api_domain_name

  certificate_arn            = aws_acm_certificate.api_cert.arn
  certificate_arn_validation = aws_acm_certificate_validation.api_cert_validation

  vpc_link_id = aws_apigatewayv2_vpc_link.main.id
  nlb_uri     = "http://${module.nlb.dns_name}:8000"

  cors_origins = [var.frontend_domain_name]
  cors_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
  cors_methods = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]

  enable_waf  = true
  web_acl_arn = module.waf.regional_waf_web_acl_arn

  tags = local.common_tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  providers = {
    aws = aws.us_east_1
  }

  name_prefix = local.name_prefix

  origins = [
    {
      domain_name = replace(module.api_gateway.api_custom_domain_name_target, "https://", "")
      origin_id   = "api-gateway-origin"
      origin_path = "/"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    },
    {
      domain_name              = module.s3.main_bucket_domain_name
      origin_id                = "s3-origin"
      origin_path              = "/"
      custom_origin_config     = null
      origin_access_control_id = module.s3.main_bucket_oac
    }
  ]

  cache_behaviors = [
    {
      path_pattern             = "/api/v1/*"
      target_origin_id         = "api-gateway-origin"
      compress                 = true
      viewer_protocol_policy   = "redirect-to-https"
      cache_policy_id          = aws_cloudfront_cache_policy.api_cache_policy.id
      origin_request_policy_id = aws_cloudfront_origin_request_policy.api_origin_policy.id
    },
    {
      path_pattern           = "/snap/*"
      target_origin_id       = "s3-origin"
      compress               = true
      viewer_protocol_policy = "redirect-to-https"
      cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    }
  ]

  default_cache_behavior = {
    target_origin_id       = "api-gateway-origin"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }

  certificate_arn            = aws_acm_certificate.api_cert.arn
  certificate_arn_validation = aws_acm_certificate_validation.api_cert_validation

  geo_restriction = {
    restriction_type = "none"
    locations        = []
  }

  logging_config = {
    bucket          = module.s3.logging_bucket_name
    prefix          = "cloudfront-logs/"
    include_cookies = false
  }

  aliases    = [var.api_domain_name]
  web_acl_id = module.waf.cloudfront_waf_web_acl_arn

  cors_origins = [var.frontend_domain_name]

  tags = local.common_tags
}

module "waf" {
  source = "../../modules/waf"

  name_prefix = local.name_prefix

  cloudfront_web_acl_name = "${local.name_prefix}-cloudfront-waf"
  regional_web_acl_name   = "${local.name_prefix}-regional-waf"

  tags = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix

  account_id = local.account_id
  region     = local.region

  s3_bucket_arn   = module.s3.main_bucket_arn
  rds_db_username = var.rds_db_username
  rds_resource_id = module.rds.resource_id

  rds_secret_arn                    = module.rds.secret_arn
  redis_secret_arn                  = module.redis.secret_arn
  kafka_secret_arn                  = module.confluent_kafka.secret_arn
  mongodb_secret_arn                = module.mongodb.secret_arn
  google_client_id_secret_arn       = module.ecs.google_client_id_secret_arn
  google_client_secret_secret_arn   = module.ecs.google_client_secret_secret_arn
  facebook_client_id_secret_arn     = module.ecs.facebook_client_id_secret_arn
  facebook_client_secret_secret_arn = module.ecs.facebook_client_secret_secret_arn
  apple_client_id_secret_arn        = module.ecs.apple_client_id_secret_arn
  apple_client_secret_secret_arn    = module.ecs.apple_client_secret_secret_arn
  owner_email_secret_arn            = module.ecs.owner_email_secret_arn
  roboflow_api_key_secret_arn       = module.ecs.roboflow_api_key_secret_arn
  smtp_email_app_pass_secret_arn    = module.ecs.smtp_email_app_pass_secret_arn
  grafana_loki_url_secret_arn       = module.ecs.grafana_loki_url_secret_arn
  grafana_loki_username_secret_arn  = module.ecs.grafana_loki_username_secret_arn
  grafana_loki_password_secret_arn  = module.ecs.grafana_loki_password_secret_arn
  app_csrf_secret_key_secret_arn    = module.ecs.app_csrf_secret_key_secret_arn

  tags = local.common_tags
}

module "grafana" {
  source = "../../modules/grafana"

  name_prefix = local.name_prefix

  account_id  = local.account_id
  external_id = var.grafana_cloud_external_id

  tags = local.common_tags
}

module "cloudflare" {
  source = "../../modules/cloudflare"

  name_prefix = local.name_prefix

  zone_id                             = data.cloudflare_zone.curby_org.id
  cloudfront_distribution_domain_name = module.cloudfront.distribution_domain_name
  certificate_arn_dvo                 = aws_acm_certificate.api_cert.domain_validation_options
}

module "redis" {
  source = "../../modules/redis"

  name_prefix = local.name_prefix

  plan_id           = data.rediscloud_essentials_plan.free.id
  payment_method_id = data.rediscloud_payment_method.visa.id

  tags = local.common_tags
}

module "mongodb" {
  source = "../../modules/mongodb"

  name_prefix = local.name_prefix

  org_id   = var.mongodbatlas_org_id
  password = var.mongodbatlas_db_password
  db_name  = var.mongodb_db_name
}

module "confluent_kafka" {
  source      = "../../modules/confluent_kafka"
  name_prefix = local.name_prefix
}

resource "aws_acm_certificate" "api_cert" {
  provider = aws.us_east_1

  domain_name       = var.api_domain_name
  validation_method = "DNS"

  tags = {
    Name        = "${local.name_prefix}-api-domain-cert"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "api_cert_validation" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in module.cloudflare.record_cert_validation : record.hostname]
}

resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${local.name_prefix}-vpc-link"
  security_group_ids = [module.ec2.ec2_security_group_id]
  subnet_ids         = module.vpc.private_subnet_ids

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc-link" })
}

resource "aws_cloudfront_cache_policy" "api_cache_policy" {
  provider = aws.us_east_1

  name = "${local.name_prefix}-api-cache-policy"

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Content-Type", "Origin", "Accept"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }

  default_ttl = 0
  min_ttl     = 0
  max_ttl     = 300
}

resource "aws_cloudfront_origin_request_policy" "api_origin_policy" {
  provider = aws.us_east_1

  name = "${local.name_prefix}-api-origin-policy"

  query_strings_config {
    query_string_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"

    headers {
      items = ["Authorization", "Content-Type", "Origin", "Accept", "User-Agent"]
    }
  }

  cookies_config {
    cookie_behavior = "none"
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.nlb.arn],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", module.nlb.arn],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", module.rds.identifier],
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.ec2.asg_name]
          ]
          period = 300
          stat   = "Average"
          region = local.region
          title  = "Overview of Curby Storage production metrics and resources"
        }
      }
    ]
  })
}
