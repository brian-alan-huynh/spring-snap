locals {
  uri_template = mongodbatlas_cluster.main.connection_strings[0].standard_srv

  connection_string = replace(
    local.uri_template,
    "mongodb+srv://",
    "mongodb+srv://${mongodbatlas_database_user.main.username}:${var.password}@"
  )
}

resource "mongodbatlas_project" "main" {
  name   = "${var.name_prefix}-mongodb-project"
  org_id = var.org_id
}

resource "mongodbatlas_cluster" "main" {
  project_id                  = mongodbatlas_project.main.id
  name                        = "${var.name_prefix}-mongodb-cluster"
  provider_name               = "TENANT"
  provider_region_name        = "US_EAST_1"
  provider_instance_size_name = "M0"
  backing_provider_name       = "AWS"
}

resource "mongodbatlas_database_user" "main" {
  project_id         = mongodbatlas_project.main.id
  username           = "mongodbatlas_admin"
  password           = var.password
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = var.db_name
  }
}

resource "mongodbatlas_project_ip_access_list" "main" {
  project_id = mongodbatlas_project.main.id
  cidr_block = "10.0.0.0/16"
  comment    = "Allow access from VPC CIDR"
}

resource "aws_secretsmanager_secret" "main" {
  name = "${var.name_prefix}-mongodb-secret"
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = local.connection_string
}
