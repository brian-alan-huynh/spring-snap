output "iam_role_arn" {
  description = "ARN of the Grafana AWS IAM role that will be connected to Grafana Cloud's CloudWatch data source"
  value       = aws_iam_role.grafana.arn
}
