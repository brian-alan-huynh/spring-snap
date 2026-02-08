output "secret_arn" {
  description = "Secret ARN for authentication of the MongoDB Atlas cluster"
  value       = aws_secretsmanager_secret.main.arn
  sensitive   = true
}
