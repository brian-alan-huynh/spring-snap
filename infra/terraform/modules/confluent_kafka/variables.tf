variable "name_prefix" {
  description = "Prefix for the Confluent Kafka resources"
  type        = string
}

variable "topics" {
  description = "List of Kafka topics defined in Curby Storage Confluent Kafka backend app (defined in backend/infra/messaging.py)"
  type        = map(number)
  default = {
    "curby.s3"      = 2
    "curby.redis"   = 8
    "curby.mongodb" = 8
  }
}
