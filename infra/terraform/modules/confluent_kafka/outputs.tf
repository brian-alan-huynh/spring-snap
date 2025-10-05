output "bootstrap_servers" {
  description = "Kafka cluster bootstrap server endpoint"
  value       = confluent_kafka_cluster.main.bootstrap_endpoint
}

output "secret_arn" {
  description = "Confluent Kafka API secret ARN"
  value       = aws_secretsmanager_secret.springsnap.arn
  sensitive = true
}

# For use in outputs.tf to write in /backend/.env file
output "api_key" {
  description = "Confluent Kafka API key"
  value       = local.api_key
}

output "api_secret" {
  description = "Confluent Kafka API secret"
  value       = local.api_secret
}
