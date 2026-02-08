output "secret_arn" {
  description = "Confluent Kafka API secret ARN"
  value       = aws_secretsmanager_secret.main.arn
  sensitive   = true
}

output "bootstrap_servers" {
  description = "Kafka cluster bootstrap server endpoint"
  value       = confluent_kafka_cluster.main.bootstrap_endpoint
}
