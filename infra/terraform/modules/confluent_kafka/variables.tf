variable "name_prefix" {
  description = "Prefix for the Confluent Kafka resources"
  type        = string
}

variable "topics" {
  description = "List of Kafka topics defined in Springsnap"
  type        = map(number)
  default = {
    "springsnap.s3"      = 2
    "springsnap.redis"   = 8
    "springsnap.mongodb" = 8
  }

  validation {
    condition     = can([var.topics, "springsnap.s3", "springsnap.redis", "springsnap.mongodb"])
    error_message = "Topics must be springsnap.s3, springsnap.redis, or springsnap.mongodb"
  }
}
