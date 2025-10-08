terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5.0"
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
    bucket       = "springsnap-state-dev"
    key          = "dev/terraform.tfstate"
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
    }
  }
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
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "TerraformInfrastructure"
    Owner       = var.owner_email
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

  local_cidr_block = "${chomp(data.http.local_public_ip.response_body)}/32"

  environment = var.environment
  kms_policy  = local.kms_policy

  tags = local.common_tags
}


module "s3" {
  source = "../../modules/s3"

  name_prefix = local.name_prefix

  environment = var.environment
  account_id  = local.account_id

  tags = local.common_tags
}

module "grafana" {
  source = "../../modules/grafana"

  name_prefix = local.name_prefix

  account_id  = local.account_id
  external_id = var.grafana_cloud_external_id

  tags = local.common_tags
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
