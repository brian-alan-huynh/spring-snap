resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_security_group" "main" {
  name   = "${var.name_prefix}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "PostgreSQL from EC2 instance app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  ingress {
    description = "PostgreSQL from local/personal machine"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.local_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_db_parameter_group" "main" {
  family = "postgres17"
  name   = "${var.name_prefix}-rds-parameter-group"

  parameter {
    name         = "ssl"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_statement"
    value        = "all"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = var.environment == "prod" ? "1000" : "5000"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_lock_waits"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "password_encryption"
    value        = "scram-sha-256"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pgaudit"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "track_activity_query_size"
    value        = "2048"
    apply_method = "immediate"
  }

  parameter {
    name         = "max_connections"
    value        = var.environment == "prod" ? "200" : "100"
    apply_method = "pending-reboot"
  }

  tags = var.tags
}

resource "aws_db_instance" "main" {
  identifier     = "${var.name_prefix}-rds"
  engine         = "postgres"
  engine_version = "17.5"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.main.arn

  manage_master_user_password         = true
  iam_database_authentication_enabled = true

  db_name  = var.db_name
  username = var.db_username
  password = jsondecode(aws_secretsmanager_secret_version.main.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.main.id]
  publicly_accessible    = false

  multi_az = var.environment == "prod" ? true : false

  backup_retention_period  = 14
  backup_window            = "03:00-04:00"
  copy_tags_to_snapshot    = true
  delete_automated_backups = false

  deletion_protection = var.environment == "prod" ? true : false

  maintenance_window          = "sun:04:00-sun:05:00"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = false

  monitoring_interval             = 90
  monitoring_role_arn             = aws_iam_role.rds_monitoring_role.arn
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  performance_insights_enabled          = true
  performance_insights_retention_period = var.environment == "prod" ? 731 : 7
  performance_insights_kms_key_id       = aws_kms_key.main.arn

  parameter_group_name = aws_db_parameter_group.main.name

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.main,
    aws_kms_key.main,
    aws_db_parameter_group.main,
    aws_iam_role.rds_monitoring_role
  ]

  tags = var.tags
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.name_prefix}-rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Server = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_role" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "${var.name_prefix}-rds-db-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors changes to the CPU utilization of the RDS instance."

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "db_free_storage" {
  alarm_name          = "${var.name_prefix}-rds-db-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "2147483648"
  alarm_description   = "This metric monitors changes to the free storage space of the RDS instance."

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "random_password" "master_password" {
  length           = 18
  special          = true
  override_special = "_!%^&*()"
  min_special      = 1
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

resource "aws_secretsmanager_secret" "main" {
  name = "${var.name_prefix}-rds-secret"
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master_password.result
    db_name  = aws_db_instance.main.db_name
    db_host  = aws_db_instance.main.address
    db_port  = aws_db_instance.main.port
  })
}

resource "aws_kms_key" "main" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = var.kms_policy

  tags = var.tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.name_prefix}-rds"
  target_key_id = aws_kms_key.main.id
}


resource "null_resource" "grant_rds_iam_role_app_user" {
  triggers = {
    db_address   = aws_db_instance.main.address
    app_username = var.db_app_username
  }

  provisioner "local-exec" {
    command = <<-EOT
      psql -h ${aws_db_instance.main.address} -U ${var.db_username} -d ${var.db_name} -c "
        CREATE ROLE ${var.db_app_username} WITH LOGIN IF NOT EXISTS;
        GRANT rds_iam TO ${var.db_app_username};
      "
    EOT

    environment = {
      PGPASSWORD = jsondecode(aws_secretsmanager_secret_version.main.secret_string)["password"]
    }
  }

  depends_on = [aws_db_instance.main]
}
