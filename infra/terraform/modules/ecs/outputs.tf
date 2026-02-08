output "cluster_name" {
  description = "Cluster name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "google_client_id_secret_arn" {
  description = "Google client ID secret ARN"
  value       = aws_secretsmanager_secret.google_client_id.arn
}

output "google_client_secret_secret_arn" {
  description = "Google client secret secret ARN"
  value       = aws_secretsmanager_secret.google_client_secret.arn
}

output "facebook_client_id_secret_arn" {
  description = "Facebook client ID secret ARN"
  value       = aws_secretsmanager_secret.facebook_client_id.arn
}

output "facebook_client_secret_secret_arn" {
  description = "Facebook client secret secret ARN"
  value       = aws_secretsmanager_secret.facebook_client_secret.arn
}

output "apple_client_id_secret_arn" {
  description = "Apple client ID secret ARN"
  value       = aws_secretsmanager_secret.apple_client_id.arn
}

output "apple_client_secret_secret_arn" {
  description = "Apple client secret secret ARN"
  value       = aws_secretsmanager_secret.apple_client_secret.arn
}

output "owner_email_secret_arn" {
  description = "Owner email secret ARN"
  value       = aws_secretsmanager_secret.owner_email.arn
}

output "roboflow_api_key_secret_arn" {
  description = "Roboflow API key secret ARN"
  value       = aws_secretsmanager_secret.roboflow_api_key.arn
}

output "smtp_email_app_pass_secret_arn" {
  description = "SMTP email app pass secret ARN"
  value       = aws_secretsmanager_secret.smtp_email_app_pass.arn
}

output "grafana_loki_url_secret_arn" {
  description = "Grafana Loki URL secret ARN"
  value       = aws_secretsmanager_secret.grafana_loki_url.arn
}

output "grafana_loki_username_secret_arn" {
  description = "Grafana Loki username secret ARN"
  value       = aws_secretsmanager_secret.grafana_loki_username.arn
}

output "grafana_loki_password_secret_arn" {
  description = "Grafana Loki password secret ARN"
  value       = aws_secretsmanager_secret.grafana_loki_password.arn
}

output "app_csrf_secret_key_secret_arn" {
  description = "App CSRF secret key secret ARN"
  value       = aws_secretsmanager_secret.app_csrf_secret_key.arn
}
