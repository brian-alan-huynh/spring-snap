output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.main.id
}

output "dns_name" {
  description = "The DNS name of the NLB"
  value       = aws_lb.main.dns_name
}

output "arn" {
  description = "The ARN of the NLB"
  value       = aws_lb.main.arn
}
