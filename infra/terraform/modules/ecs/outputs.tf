output "cluster_name" {
  description = "Cluster name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}
