# Project
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "aws_account_id" {
  description = "AWS Account ID where resources are deployed"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region_name" {
  description = "AWS Region where resources are deployed"
  value       = data.aws_region.current.name
}

output "environment_info" {
  description = "Environment information for reference"
  value = {
    project_name = var.project_name
    environment  = var.environment
    aws_region   = var.aws_region
    name_prefix  = local.name_prefix
  }
}

# VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets"
  value       = module.vpc.public_subnet_arns
}

output "private_subnet_arns" {
  description = "ARNs of the private subnets"
  value       = module.vpc.private_subnet_arns
}

output "public_route_table_ids" {
  description = "IDs of the public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "vpc_default_security_group_id" {
  description = "ID of the default security group for the VPC"
  value       = module.vpc.default_security_group_id
}

# RDS
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.instance_id
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds.instance_arn
}

output "connection_string_template" {
  description = "Template for database connection string (without credentials)"
  value       = "postgresql://<username>:<password>@${module.rds.endpoint}:${module.rds.port}/${module.rds.db_name}"
  sensitive   = false
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
  sensitive   = false # Endpoint is not sensitive, but connection details are
}

output "rds_username" {
  description = "RDS instance username"
  value       = module.rds.username
}

output "rds_db_host" {
  description = "RDS instance host"
  value       = module.rds.db_host
}

output "rds_db_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "rds_db_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds.security_group_id
}

output "rds_parameter_group_name" {
  description = "Name of the RDS parameter group"
  value       = module.rds.parameter_group_name
}

output "rds_subnet_group_name" {
  description = "Name of the RDS subnet group"
  value       = module.rds.subnet_group_name
}

# S3
output "s3_main_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.main_bucket_name
}

output "s3_main_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.main_bucket_arn
}

output "s3_main_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = module.s3.main_bucket_domain_name
}

output "s3_main_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = module.s3.main_bucket_regional_domain_name
}

# Confluent Kafka
output "kafka_cluster_id" {
  description = "ID of the Confluent Kafka cluster"
  value       = module.confluent_kafka.cluster_id
}

output "kafka_cluster_bootstrap_endpoint" {
  description = "Kafka cluster bootstrap servers endpoint"
  value       = module.confluent_kafka.bootstrap_endpoint
  sensitive   = true
}

output "kafka_cluster_rest_endpoint" {
  description = "Kafka cluster REST endpoint"
  value       = module.confluent_kafka.rest_endpoint
  sensitive   = true
}

output "kafka_api_key" {
  description = "Kafka API key for application authentication"
  value       = module.confluent_kafka.api_key_id
  sensitive   = true
}

output "kafka_api_secret" {
  description = "Kafka API secret for application authentication"
  value       = module.confluent_kafka.api_key_secret
  sensitive   = true
}

output "schema_registry_endpoint" {
  description = "Schema Registry REST endpoint"
  value       = module.confluent_kafka.schema_registry_rest_endpoint
  sensitive   = true
}

output "schema_registry_api_key" {
  description = "Schema Registry API key"
  value       = module.confluent_kafka.schema_registry_api_key_id
  sensitive   = true
}

output "schema_registry_api_secret" {
  description = "Schema Registry API secret"
  value       = module.confluent_kafka.schema_registry_api_key_secret
  sensitive   = true
}

output "topic_names" {
  description = "Map of topic names for application configuration"
  value = {
    user_events        = module.confluent_kafka.user_events_topic_name
    application_events = module.confluent_kafka.application_events_topic_name
    file_processing    = module.confluent_kafka.file_processing_topic_name
    analytics_events   = module.confluent_kafka.analytics_events_topic_name
    dead_letter_queue  = module.confluent_kafka.dead_letter_queue_topic_name
  }
}

output "environment_id" {
  description = "Confluent environment ID"
  value       = module.confluent_kafka.environment_id
}

output "service_account_id" {
  description = "Service account ID for the application"
  value       = module.confluent_kafka.service_account_id
}

output "kafka_config" {
  description = "Complete Kafka configuration for Python client"
  value = {
    bootstrap_servers    = module.confluent_kafka.bootstrap_endpoint
    sasl_mechanism       = "PLAIN"
    security_protocol    = "SASL_SSL"
    sasl_username        = module.confluent_kafka.api_key_id
    sasl_password        = module.confluent_kafka.api_key_secret
    schema_registry_url  = module.confluent_kafka.schema_registry_rest_endpoint
    schema_registry_auth = "${module.confluent_kafka.schema_registry_api_key_id}:${module.confluent_kafka.schema_registry_api_key_secret}"
  }

  sensitive = true
}

# MongoDB Atlas
output "mongodb_connection_string" {
  description = "MongoDB connection string"
  value       = module.mongodb.connection_string
}
