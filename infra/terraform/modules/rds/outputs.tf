output "username" {
  description = "Username for the RDS database"
  value       = aws_db_instance.main.username
}

output "db_host" {
  description = "Host for the RDS database"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Port for the RDS database"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name for the RDS database"
  value       = aws_db_instance.main.db_name
}

output "identifier" {
  description = "Identifier of the RDS database"
  value       = aws_db_instance.main.identifier
}

output "resource_id" {
  description = "Resource ID of the RDS database"
  value       = aws_db_instance.main.resource_id
}
