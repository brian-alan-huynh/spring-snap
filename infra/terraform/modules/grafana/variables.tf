variable "name_prefix" {
  description = "Prefix for the Grafana Cloud AWS IAM role"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "external_id" {
  description = "Grafana Cloud External ID taken from the Grafana Cloud Console"
  type        = string
}

variable "tags" {
  description = "Tags for the Grafana Cloud AWS IAM role"
  type        = map(string)
}
