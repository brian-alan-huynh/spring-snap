output "secret_arn" {
  description = "ARN for the RDS database secret"
  value       = aws_secretsmanager_secret.main.arn
  sensitive   = true
}

output "identifier" {
  description = "Identifier of the RDS database"
  value       = aws_db_instance.main.identifier
}

output "resource_id" {
  description = "Resource ID of the RDS database"
  value       = aws_db_instance.main.resource_id
}
