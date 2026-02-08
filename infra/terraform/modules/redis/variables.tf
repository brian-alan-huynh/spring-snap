variable "name_prefix" {
  description = "The name prefix for the Redis resources"
  type        = string
}

variable "plan_id" {
  description = "The ID of the Redis plan"
  type        = string
}

variable "payment_method_id" {
  description = "The ID of the payment method"
  type        = string
}

variable "tags" {
  description = "The tags for the Redis resources"
  type        = map(string)
}
