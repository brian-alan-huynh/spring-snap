output "ecr_repository_url_backend" {
  description = "URL of the backend AWS ECR repository to be used for tagging and pushing the backend docker image"
  value       = module.ecr.repository_url_backend
}

output "ecr_repository_url_frontend" {
  description = "URL of the frontend AWS ECR repository to be used for tagging and pushing the frontend docker image"
  value       = module.ecr.repository_url_frontend
}
