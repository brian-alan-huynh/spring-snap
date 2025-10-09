resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.main.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_exec.name
      }
    }
  }

  tags = var.tags
}


resource "aws_ecs_capacity_provider" "main" {
  name = "${var.name_prefix}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.asg_arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name_prefix}-backend"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "springsnap-backend"
      image = "${var.ecr_repository_url_backend}:latest"

      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "AWS_S3_BUCKET_NAME"
          value = var.s3_bucket_name
        },
        {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = var.kafka_bootstrap_servers
        },
        {
          name  = "MONGODB_DB_NAME"
          value = var.mongodb_db_name
        },
        {
          name  = "MONGODB_DB_COLLECTION_NAME"
          value = var.mongodb_db_collection_name
        },
        {
          name  = "ROBOFLOW_MODEL_PATH"
          value = var.roboflow_model_path
        },
        {
          name  = "SMTP_SERVER"
          value = var.smtp_server
        },
        {
          name  = "SMTP_SERVER_PORT"
          value = var.smtp_server_port
        }
      ]

      secrets = [
        {
          name      = "AWS_RDS_SECRET_ARN"
          valueFrom = var.rds_secret_arn
        },
        {
          name      = "REDIS_SECRET_ARN"
          valueFrom = var.redis_secret_arn
        },
        {
          name      = "KAFKA_SECRET_ARN"
          valueFrom = var.kafka_secret_arn
        },
        {
          name      = "MONGODB_SECRET_ARN"
          valueFrom = var.mongodb_secret_arn
        },
        {
          name      = "GOOGLE_CLIENT_ID"
          valueFrom = aws_secretsmanager_secret.google_client_id.arn
        },
        {
          name      = "GOOGLE_CLIENT_SECRET"
          valueFrom = aws_secretsmanager_secret.google_client_secret.arn
        },
        {
          name      = "FACEBOOK_CLIENT_ID"
          valueFrom = aws_secretsmanager_secret.facebook_client_id.arn
        },
        {
          name      = "FACEBOOK_CLIENT_SECRET"
          valueFrom = aws_secretsmanager_secret.facebook_client_secret.arn
        },
        {
          name      = "APPLE_CLIENT_ID"
          valueFrom = aws_secretsmanager_secret.apple_client_id.arn
        },
        {
          name      = "APPLE_CLIENT_SECRET"
          valueFrom = aws_secretsmanager_secret.apple_client_secret.arn
        },
        {
          name      = "EMAIL"
          valueFrom = aws_secretsmanager_secret.owner_email.arn
        },
        {
          name      = "ROBOFLOW_API_KEY"
          valueFrom = aws_secretsmanager_secret.roboflow_api_key.arn
        },
        {
          name      = "SMTP_EMAIL_APP_PASS"
          valueFrom = aws_secretsmanager_secret.smtp_email_app_pass.arn
        },
        {
          name      = "GRAFANA_LOKI_URL"
          valueFrom = aws_secretsmanager_secret.grafana_loki_url.arn
        },
        {
          name      = "GRAFANA_LOKI_USERNAME"
          valueFrom = aws_secretsmanager_secret.grafana_loki_username.arn
        },
        {
          name      = "GRAFANA_LOKI_PASSWORD"
          valueFrom = aws_secretsmanager_secret.grafana_loki_password.arn
        },
        {
          name      = "APP_CSRF_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.app_csrf_secret_key.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.name_prefix}-frontend"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "springsnap-frontend"
      image = "${var.ecr_repository_url_frontend}:latest"

      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "backend" {
  name            = "${var.name_prefix}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.nlb_target_group_arn
    container_name   = "springsnap-backend"
    container_port   = 8000
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [
    aws_ecs_capacity_provider.main,
    var.ecs_task_execution_role_definition
  ]

  tags = var.tags
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.name_prefix}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.nlb_target_group_arn
    container_name   = "springsnap-frontend"
    container_port   = 80
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [
    aws_ecs_capacity_provider.main,
    var.ecs_task_execution_role_definition
  ]

  tags = var.tags
}

resource "aws_security_group" "ecs" {
  name   = "${var.name_prefix}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "HTTP from NLB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.nlb_security_group_id]
  }

  ingress {
    description     = "HTTP from NLB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.nlb_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "ecs_exec" {
  name              = "/ecs/${var.name_prefix}/exec"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.main.arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.name_prefix}/backend"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.main.arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.name_prefix}/frontend"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.main.arn

  tags = var.tags
}

resource "aws_kms_key" "main" {
  description             = "KMS key for ECS cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = var.kms_policy

  tags = var.tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.name_prefix}-ecs"
  target_key_id = aws_kms_key.main.key_id
}

# Backend app .env secrets
resource "aws_secretsmanager_secret" "google_client_id" {
  name = "${var.name_prefix}-google-client-id-secret"
}

resource "aws_secretsmanager_secret_version" "google_client_id" {
  secret_id     = aws_secretsmanager_secret.google_client_id.id
  secret_string = var.google_client_id
}

resource "aws_secretsmanager_secret" "google_client_secret" {
  name = "${var.name_prefix}-google-client-secret"
}

resource "aws_secretsmanager_secret_version" "google_client_secret" {
  secret_id     = aws_secretsmanager_secret.google_client_secret.id
  secret_string = var.google_client_secret
}

resource "aws_secretsmanager_secret" "facebook_client_id" {
  name = "${var.name_prefix}-facebook-client-id-secret"
}

resource "aws_secretsmanager_secret_version" "facebook_client_id" {
  secret_id     = aws_secretsmanager_secret.facebook_client_id.id
  secret_string = var.facebook_client_id
}

resource "aws_secretsmanager_secret" "facebook_client_secret" {
  name = "${var.name_prefix}-facebook-client-secret"
}

resource "aws_secretsmanager_secret_version" "facebook_client_secret" {
  secret_id     = aws_secretsmanager_secret.facebook_client_secret.id
  secret_string = var.facebook_client_secret
}

resource "aws_secretsmanager_secret" "apple_client_id" {
  name = "${var.name_prefix}-apple-client-id-secret"
}

resource "aws_secretsmanager_secret_version" "apple_client_id" {
  secret_id     = aws_secretsmanager_secret.apple_client_id.id
  secret_string = var.apple_client_id
}

resource "aws_secretsmanager_secret" "apple_client_secret" {
  name = "${var.name_prefix}-apple-client-secret"
}

resource "aws_secretsmanager_secret_version" "apple_client_secret" {
  secret_id     = aws_secretsmanager_secret.apple_client_secret.id
  secret_string = var.apple_client_secret
}

resource "aws_secretsmanager_secret" "owner_email" {
  name = "${var.name_prefix}-owner-email-secret"
}

resource "aws_secretsmanager_secret_version" "owner_email" {
  secret_id     = aws_secretsmanager_secret.owner_email.id
  secret_string = var.owner_email
}

resource "aws_secretsmanager_secret" "roboflow_api_key" {
  name = "${var.name_prefix}-roboflow-api-key-secret"
}

resource "aws_secretsmanager_secret_version" "roboflow_api_key" {
  secret_id     = aws_secretsmanager_secret.roboflow_api_key.id
  secret_string = var.roboflow_api_key
}

resource "aws_secretsmanager_secret" "smtp_email_app_pass" {
  name = "${var.name_prefix}-smtp-email-app-pass-secret"
}

resource "aws_secretsmanager_secret_version" "smtp_email_app_pass" {
  secret_id     = aws_secretsmanager_secret.smtp_email_app_pass.id
  secret_string = var.smtp_email_app_pass
}

resource "aws_secretsmanager_secret" "grafana_loki_url" {
  name = "${var.name_prefix}-grafana-loki-url-secret"
}

resource "aws_secretsmanager_secret_version" "grafana_loki_url" {
  secret_id     = aws_secretsmanager_secret.grafana_loki_url.id
  secret_string = var.grafana_loki_url
}

resource "aws_secretsmanager_secret" "grafana_loki_username" {
  name = "${var.name_prefix}-grafana-loki-username-secret"
}

resource "aws_secretsmanager_secret_version" "grafana_loki_username" {
  secret_id     = aws_secretsmanager_secret.grafana_loki_username.id
  secret_string = var.grafana_loki_username
}

resource "aws_secretsmanager_secret" "grafana_loki_password" {
  name = "${var.name_prefix}-grafana-loki-password-secret"
}

resource "aws_secretsmanager_secret_version" "grafana_loki_password" {
  secret_id     = aws_secretsmanager_secret.grafana_loki_password.id
  secret_string = var.grafana_loki_password
}

resource "aws_secretsmanager_secret" "app_csrf_secret_key" {
  name = "${var.name_prefix}-app-csrf-secret-key"
}

resource "aws_secretsmanager_secret_version" "app_csrf_secret_key" {
  secret_id     = aws_secretsmanager_secret.app_csrf_secret_key.id
  secret_string = var.app_csrf_secret_key
}
