terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.0.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.25.0"
    }
  }

  backend "s3" {
    bucket       = "springsnap-terraform-state-dev"
    key          = "dev/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

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

provider "mongodbatlas" {
  public_key  = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "TerraformInfrastructure"
    Owner       = var.owner_email
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "EnableRootAndAdminaccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
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
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
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
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid    = "AllowIAMDelegation"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
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

module "vpc" {
  source = "../../modules/vpc"

  name_prefix = local.name_prefix

  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  region     = data.aws_region.current.name
  kms_policy = data.aws_iam_policy_document.kms.json

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix = local.name_prefix

  instance_class  = var.db_instance_class
  db_name         = var.db_name
  db_username     = var.db_username
  db_app_username = var.db_app_username

  subnet_ids = module.vpc.private_subnet_ids
  vpc_id     = module.vpc.vpc_id

  allowed_security_group_ids = [module.ec2.ec2_security_group_id]

  environment = var.environment
  kms_policy  = data.aws_iam_policy_document.kms.json

  tags = local.common_tags
}


module "s3" {
  source = "../../modules/s3"

  name_prefix          = local.name_prefix
  frontend_domain_name = var.frontend_domain_name
  tags                 = local.common_tags
}

module "mongodb" {
  source = "../../modules/mongodb"

  name_prefix = local.name_prefix

  org_id   = var.mongodbatlas_org_id
  password = var.mongodbatlas_db_password
}

module "confluent_kafka" {
  source      = "../../modules/confluent_kafka"
  name_prefix = local.name_prefix
}
