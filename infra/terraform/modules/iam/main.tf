# Application
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name_prefix}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.name_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "ecs_task" {
  name        = "${var.name_prefix}-ecs-task-policy"
  description = "Policy for application code access to S3, RDS, and Secrets Manager with ECS as the trusted entity"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Sid      = "AllowRDS",
        Effect   = "Allow",
        Action   = "rds-db:connect",
        Resource = "arn:aws:rds:${var.region}:${var.account_id}:dbuser:${var.rds_resource_id}/${var.rds_db_username}"
      },
      {
        Sid    = "AllowSecretsManager",
        Effect = "Allow",
        Action = "secretsmanager:GetSecretValue",
        Resource = [
          var.rds_secret_arn,
          var.redis_secret_arn,
          var.kafka_secret_arn,
          var.mongodb_secret_arn,
          var.google_client_id_secret_arn,
          var.google_client_secret_secret_arn,
          var.facebook_client_id_secret_arn,
          var.facebook_client_secret_secret_arn,
          var.apple_client_id_secret_arn,
          var.apple_client_secret_secret_arn,
          var.owner_email_secret_arn,
          var.roboflow_api_key_secret_arn,
          var.smtp_email_app_pass_secret_arn,
          var.grafana_loki_url_secret_arn,
          var.grafana_loki_username_secret_arn,
          var.grafana_loki_password_secret_arn,
          var.app_csrf_secret_key_secret_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task.arn
}

resource "aws_iam_role" "ec2" {
  name = "${var.name_prefix}-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.ec2
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2.name
}
