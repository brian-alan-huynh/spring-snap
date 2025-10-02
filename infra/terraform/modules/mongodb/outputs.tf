output "secret_arn" {
  description = "Secret ARN for authentication of the MongoDB Atlas cluster"
  value       = aws_secretsmanager_secret.main.arn
  sensitive   = true
}

# For use in outputs.tf to write in /backend/.env file
output "connection_string" {
  description = "The connection string for the MongoDB Atlas cluster"
  value       = local.connection_string
}
