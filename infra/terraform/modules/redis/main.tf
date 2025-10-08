resource "rediscloud_essentials_subscription" "main" {
  name              = "${var.name_prefix}-free-subscription"
  plan_id           = var.plan_id
  payment_method_id = var.payment_method_id
}

resource "rediscloud_essentials_database" "main" {
  name             = "${var.name_prefix}-free-30MB"
  subscription_id  = rediscloud_essentials_subscription.main.id
  data_persistence = "none"
  replication      = false

  depends_on = [rediscloud_essentials_subscription.main]

  tags = var.tags
}

resource "aws_secretsmanager_secret" "main" {
  name = "${var.name_prefix}-redis-secret"
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id

  secret_string = jsonencode({
    host     = element(split(":", element(split("@", rediscloud_essentials_database.main.public_endpoint), 1)), 0)
    port     = element(split(":", element(split("@", rediscloud_essentials_database.main.public_endpoint), 1)), 1)
    password = rediscloud_essentials_database.main.password
  })
}
