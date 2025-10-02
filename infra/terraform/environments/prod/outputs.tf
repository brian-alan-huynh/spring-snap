output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.distribution_domain_name
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.api_gateway.api_id
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "nlb_dns_name" {
  description = "Network Load Balancer DNS name"
  value       = module.nlb.dns_name
}

output "s3_main_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.main_bucket_name
}

output "s3_cloudfront_logs_bucket_name" {
  description = "CloudFront logs S3 bucket name"
  value       = module.s3.cloudfront_logs_bucket_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
}

output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.ec2.autoscaling_group_name
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.api_cert.arn
}

output "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  value       = data.cloudflare_zone.springsnap_org.id
}

output "confluent_kafka_bootstrap_servers" {
  description = "Confluent Kafka bootstrap servers"
  value       = module.confluent_kafka.bootstrap_servers
}

output "confluent_kafka_api_key" {
  description = "Confluent Kafka API key"
  value       = module.confluent_kafka.api_key
}

output "confluent_kafka_api_secret" {
  description = "Confluent Kafka API secret"
  value       = module.confluent_kafka.api_secret
}

output "mongodb_connection_string" {
  description = "MongoDB connection string"
  value       = module.mongodb.connection_string
}

output "iam_grafana_role_arn" {
  description = "ARN of the Grafana IAM role"
  value       = module.iam.grafana_iam_role_arn
}
