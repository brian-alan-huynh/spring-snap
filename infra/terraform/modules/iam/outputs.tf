output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_task_execution_role_definition" {
  description = "ARN of the ECS role policy attachment for task execution"
  value       = aws_iam_role_policy_attachment.ecs_task_execution
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name for ECS cluster instances"
  value       = aws_iam_instance_profile.ec2.name
}

output "grafana_iam_role_arn" {
  description = "ARN of the Grafana IAM role"
  value       = aws_iam_role.grafana.arn
}
