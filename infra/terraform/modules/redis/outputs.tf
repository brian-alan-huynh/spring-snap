output "secret_arn" {
  description = "Redis secret ARN"
  value       = aws_secretsmanager_secret.main.arn
  sensitive   = true
}
