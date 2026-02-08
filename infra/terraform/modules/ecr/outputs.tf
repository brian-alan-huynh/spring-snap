output "repository_url_backend" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.main["backend"].repository_url
}

output "repository_url_frontend" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.main["frontend"].repository_url
}
