output "grafana_iam_role_arn" {
  description = "ARN of the Grafana AWS IAM role that will be connected to Grafana Cloud's CloudWatch data source"
  value       = module.grafana.iam_role_arn
}

# Backend app .env outputs (values sent to run_terraform_dev.sh)
output "aws_region" {
  description = "AWS region"
  value       = local.region
}

output "aws_rds_secret_arn" {
  description = "AWS RDS secret ARN used to dynamically fetch the username, password, database name, host, and port in config.py boto3 client"
  value       = module.rds.secret_arn
}

output "aws_s3_bucket_name" {
  description = "AWS S3 bucket name"
  value       = module.s3.main_bucket_name
}

output "kafka_secret_arn" {
  description = "Confluent Kafka secret ARN used to dynamically fetch the API key and secret in config.py boto3 client"
  value       = module.confluent_kafka.secret_arn
}

output "kafka_bootstrap_servers" {
  description = "Confluent Kafka bootstrap servers"
  value       = module.confluent_kafka.bootstrap_servers
}

output "redis_secret_arn" {
  description = "Redis secret ARN used to dynamically fetch the password in config.py boto3 client"
  value       = module.redis.secret_arn
}

output "mongodb_secret_arn" {
  description = "MongoDB secret ARN used to dynamically fetch the connection string in config.py boto3 client"
  value       = module.mongodb.secret_arn
}

output "mongodb_db_name" {
  description = "MongoDB database name"
  value       = var.mongodb_db_name
}
