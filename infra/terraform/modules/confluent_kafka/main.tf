resource "confluent_environment" "main" {
  display_name = "${var.name_prefix}-environment"

  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_kafka_cluster" "main" {
  display_name = "${var.name_prefix}-kafka-cluster"
  availability = "MULTI_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"

  dedicated {
    cku = 2
  }

  environment {
    id = confluent_environment.main.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_service_account" "curby" {
  display_name = "${var.name_prefix}-service-account"
  description  = "Service account for Curby application with Confluent Kafka access"
}

resource "confluent_api_key" "curby_app_api_key" {
  display_name = "${var.name_prefix}-app-api-key"
  description  = "Confluent Kafka API key for Curby application"

  owner {
    id          = confluent_service_account.curby.id
    api_version = confluent_service_account.curby.api_version
    kind        = confluent_service_account.curby.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.main.id
    api_version = confluent_kafka_cluster.main.api_version
    kind        = confluent_kafka_cluster.main.kind

    environment {
      id = confluent_environment.main.id
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_kafka_acl" "curby_topic_admin" {
  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }

  resource_type = "TOPIC"
  resource_name = "curby.*"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.curby.id}"
  host          = "*"
  operation     = "ALL"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.main.rest_endpoint

  credentials {
    key    = confluent_api_key.curby_app_api_key.id
    secret = confluent_api_key.curby_app_api_key.secret
  }
}

resource "confluent_kafka_acl" "curby_consumer_group" {
  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }

  resource_type = "GROUP"
  resource_name = "curby-*"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.curby.id}"
  host          = "*"
  operation     = "ALL"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.main.rest_endpoint

  credentials {
    key    = confluent_api_key.curby_app_api_key.id
    secret = confluent_api_key.curby_app_api_key.secret
  }
}

resource "confluent_kafka_topic" "curby" {
  for_each = var.topics

  kafka_cluster {
    id = confluent_kafka_cluster.main.id
  }

  topic_name       = each.key
  partitions_count = each.value
  rest_endpoint    = confluent_kafka_cluster.main.rest_endpoint

  config = {
    "max.message.bytes"              = "10485760"
    "min.insync.replicas"            = "2"
    "unclean.leader.election.enable" = "false"
    "compression.type"               = "snappy"
    "segment.ms"                     = "604800000"
    "retention.ms"                   = "604800000"
    "retention.bytes"                = "-1"
    "cleanup.policy"                 = "delete"
  }

  credentials {
    key    = confluent_api_key.curby_app_api_key.id
    secret = confluent_api_key.curby_app_api_key.secret
  }
}

resource "aws_secretsmanager_secret" "main" {
  name = "${var.name_prefix}-kafka-secret"
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id

  secret_string = jsonencode({
    key    = confluent_api_key.curby_app_api_key.id
    secret = confluent_api_key.curby_app_api_key.secret
  })
}
