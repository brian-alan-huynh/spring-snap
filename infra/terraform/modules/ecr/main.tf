resource "aws_ecr_repository" "main" {
    for_each = toset(var.repository_app_names)

    name = "${var.name_prefix}-${each.value}"
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
      scan_on_push = true
    }
  
    encryption_configuration {
        encryption_type = "KMS"
        kms_key = aws_kms_key.main.arn
    }

    tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "main" {
    for_each = toset(var.repository_app_names)

    repository = aws_ecr_repository.main[each.value].name

    policy = jsonencode({
        rules = [
            {
                rulePriority = 1
                description = "Keep the last 10 images"
                selection = {
                    tagStatus = "any"
                    countType = "imageCountMoreThan"
                    countNumber = 10
                }
                action = {
                    type = "expire"
                }
            }
        ]
    })
}

resource "aws_kms_key" "main" {
    description = "KMS key for ECR repository encryption"
    deletion_window_in_days = 7
    enable_key_rotation = true
    policy = var.kms_policy

    tags = var.tags
}

resource "aws_kms_alias" "main" {
    name = "alias/${var.name_prefix}-ecr"
    target_key_id = aws_kms_key.main.key_id
}
