variable "name_prefix" {
  description = "The name prefix for the MongoDB resources"
  type        = string
}

variable "org_id" {
  description = "The ID of the MongoDB Atlas organization"
  type        = string
}

variable "password" {
  description = "The password for the MongoDB Atlas user"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}
